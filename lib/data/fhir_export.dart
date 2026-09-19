import 'dart:convert';

import 'case_store.dart';
import 'triage.dart';

/// Builds an HL7 FHIR R4 transaction Bundle from one self-check.
///
/// The Connectathon rule is interoperability by design: the case has to leave
/// the app in a shape the hospital information system can ingest, not as a
/// private JSON blob. Photos are referenced, not inlined, because the imaging
/// path for this project is a DICOMweb store (VL Photographic Image).
class FhirExport {
  static String build(FootCase footCase) {
    final patientId = 'patient-${footCase.patientId}';
    final encounterId = 'encounter-${footCase.shortId}';
    final date = footCase.createdAt;

    final entries = <Map<String, dynamic>>[];

    // ---- Patient ---------------------------------------------------------
    entries.add(_entry('Patient', patientId, {
      'resourceType': 'Patient',
      'id': patientId,
      'identifier': [
        {
          'system': 'urn:oid:2.16.788.1.1.1',
          'value': footCase.patientId,
          'type': {
            'text': 'Identifiant National de Santé (INS) - placeholder',
          }
        }
      ],
      'name': [
        {'text': footCase.patientName}
      ],
      'active': true,
    }));

    // ---- QuestionnaireResponse ------------------------------------------
    final items = <Map<String, dynamic>>[];
    footCase.answers.forEach((key, value) {
      final Map<String, dynamic> answer = value is bool
          ? <String, dynamic>{'valueBoolean': value}
          : <String, dynamic>{'valueString': '$value'};
      items.add(<String, dynamic>{
        'linkId': key,
        'text': key,
        'answer': <Map<String, dynamic>>[answer],
      });
    });

    entries.add(_entry('QuestionnaireResponse', 'qr-${footCase.shortId}', {
      'resourceType': 'QuestionnaireResponse',
      'id': 'qr-${footCase.shortId}',
      'status': 'completed',
      'subject': {'reference': 'Patient/$patientId'},
      'authored': date,
      'questionnaire': 'urn:khatwa:questionnaire:diabetic-foot-selfcheck|1.0',
      'item': items,
    }));

    // ---- Observations, one per finding -----------------------------------
    for (var i = 0; i < footCase.triage.findings.length; i++) {
      final finding = footCase.triage.findings[i];
      entries.add(_entry('Observation', 'obs-${footCase.shortId}-$i', {
        'resourceType': 'Observation',
        'id': 'obs-${footCase.shortId}-$i',
        'status': 'preliminary',
        'category': [
          {
            'coding': [
              {
                'system': 'http://terminology.hl7.org/CodeSystem/observation-category',
                'code': 'exam',
                'display': 'Exam',
              }
            ]
          }
        ],
        'code': {
          'coding': [
            {
              'system': 'http://snomed.info/sct',
              'code': _snomed(finding.label),
              'display': finding.label,
            }
          ],
          'text': finding.label,
        },
        'subject': {'reference': 'Patient/$patientId'},
        'effectiveDateTime': date,
        'valueString': finding.detail,
        'note': [
          {'text': 'source=${finding.source}; severity=${finding.severity}'}
        ],
      }));
    }

    // ---- Media, one per photo -------------------------------------------
    for (var i = 0; i < footCase.photos.length; i++) {
      final label = i < footCase.photoLabels.length ? footCase.photoLabels[i] : 'foot photo';
      entries.add(_entry('Media', 'media-${footCase.shortId}-$i', {
        'resourceType': 'Media',
        'id': 'media-${footCase.shortId}-$i',
        'status': 'completed',
        'type': {
          'coding': [
            {
              'system': 'http://terminology.hl7.org/CodeSystem/media-type',
              'code': 'image',
              'display': 'Image',
            }
          ]
        },
        'modality': {
          'coding': [
            {
              'system': 'http://dicom.nema.org/resources/ontology/DCM',
              'code': 'XC',
              'display': 'External-camera Photography',
            }
          ]
        },
        'bodySite': {'text': label},
        'subject': {'reference': 'Patient/$patientId'},
        'createdDateTime': date,
        'content': {
          'contentType': 'image/jpeg',
          'url': 'urn:khatwa:photo:${footCase.shortId}:$i',
          'title': label,
        },
      }));
    }

    // ---- RiskAssessment (the AI output) ----------------------------------
    final basis = <Map<String, dynamic>>[];
    for (var i = 0; i < footCase.photos.length; i++) {
      basis.add(<String, dynamic>{'reference': 'Media/media-${footCase.shortId}-$i'});
    }
    basis.add(<String, dynamic>{
      'reference': 'QuestionnaireResponse/qr-${footCase.shortId}'
    });

    entries.add(_entry('RiskAssessment', 'risk-${footCase.shortId}', {
      'resourceType': 'RiskAssessment',
      'id': 'risk-${footCase.shortId}',
      'status': 'preliminary',
      'subject': {'reference': 'Patient/$patientId'},
      'occurrenceDateTime': date,
      'method': {
        'text': footCase.triage.source == 'rules'
            ? 'Khatwa clinical rule engine'
            : 'Khatwa clinical rule engine + Gemini multimodal triage',
      },
      'prediction': [
        {
          'outcome': {'text': 'Diabetic foot warning signs'},
          'qualitativeRisk': {
            'coding': [
              {
                'system': 'http://terminology.hl7.org/CodeSystem/risk-probability',
                'code': _riskCode(footCase.triage.level),
                'display': levelToString(footCase.triage.level),
              }
            ]
          },
          'rationale': footCase.triage.clinicianSummary,
        }
      ],
      'note': [
        {'text': 'confidence=${footCase.triage.confidence}; photoQuality=${footCase.triage.photoQuality}'}
      ],
      'basis': basis,
    }));

    // ---- ServiceRequest (the referral, only once validated) ---------------
    final decision = footCase.decision;
    if (decision != null) {
      entries.add(_entry('ServiceRequest', 'referral-${footCase.shortId}', {
        'resourceType': 'ServiceRequest',
        'id': 'referral-${footCase.shortId}',
        'status': 'active',
        'intent': 'order',
        'priority': decision['level'] == 'red' ? 'urgent' : 'routine',
        'subject': {'reference': 'Patient/$patientId'},
        'authoredOn': decision['date'],
        'requester': {'display': '${decision['doctor']}'},
        'code': {'text': 'Évaluation du pied diabétique'},
        'locationReference': [
          {'display': '${decision['orientation']}'}
        ],
        'note': [
          {'text': '${decision['note']}'}
        ],
      }));
    }

    // ---- Provenance ------------------------------------------------------
    final agents = <Map<String, dynamic>>[
      <String, dynamic>{
        'type': {
          'coding': [
            {
              'system':
                  'http://terminology.hl7.org/CodeSystem/provenance-participant-type',
              'code': 'author',
            }
          ]
        },
        'who': {'display': 'Khatwa mobile app (patient self-capture)'},
      },
    ];
    if (decision != null) {
      agents.add(<String, dynamic>{
        'type': {
          'coding': [
            {
              'system':
                  'http://terminology.hl7.org/CodeSystem/provenance-participant-type',
              'code': 'verifier',
            }
          ]
        },
        'who': {'display': '${decision['doctor']}'},
      });
    }
    entries.add(_entry('Provenance', 'prov-${footCase.shortId}', {
      'resourceType': 'Provenance',
      'id': 'prov-${footCase.shortId}',
      'target': [
        {'reference': 'RiskAssessment/risk-${footCase.shortId}'}
      ],
      'recorded': date,
      'agent': agents,
      'entity': [
        {
          'role': 'source',
          'what': {'display': 'Encounter/$encounterId'},
        }
      ],
    }));

    final bundle = {
      'resourceType': 'Bundle',
      'id': 'khatwa-${footCase.shortId}',
      'type': 'transaction',
      'timestamp': date,
      'entry': entries,
    };

    return const JsonEncoder.withIndent('  ').convert(bundle);
  }

  static Map<String, dynamic> _entry(
    String resourceType,
    String id,
    Map<String, dynamic> resource,
  ) =>
      {
        'fullUrl': 'urn:uuid:$id',
        'resource': resource,
        'request': {'method': 'POST', 'url': resourceType},
      };

  static String _riskCode(TriageLevel level) {
    switch (level) {
      case TriageLevel.red:
        return 'high';
      case TriageLevel.amber:
        return 'moderate';
      case TriageLevel.green:
        return 'low';
    }
  }

  /// Indicative SNOMED CT concepts. SNOMED licensing in Tunisia has to be
  /// confirmed; until then these map to a local code system of the same shape.
  static String _snomed(String label) {
    final l = label.toLowerCase();
    if (l.contains('ulcer') || l.contains('plaie') || l.contains('جرح')) return '371127007';
    if (l.contains('callus') || l.contains('corne') || l.contains('hyperkerat')) return '61587004';
    if (l.contains('fissure') || l.contains('crevasse')) return '48333001';
    if (l.contains('red') || l.contains('rougeur') || l.contains('erythem')) return '247441003';
    if (l.contains('swell') || l.contains('gonfle') || l.contains('انتفاخ')) return '65124004';
    if (l.contains('infect')) return '128045006';
    if (l.contains('numb') || l.contains('sensation') || l.contains('neuropath')) return '44077006';
    return '410394004';
  }
}
