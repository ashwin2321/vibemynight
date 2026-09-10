import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../models/pass_template.dart';

const _kPassTemplatesStorageKey = 'vmn_pass_templates_v1';
const _storage = FlutterSecureStorage();

final defaultPassTemplates = <PassTemplate>[
  const PassTemplate(
    id: 'tpl_early_200',
    name: 'Early Entry Pass',
    type: 'REGULAR',
    price: 200.0,
    defaultQuantity: 300,
    maxPerCustomer: 5,
    benefits: ['Entry before 8:30 PM', 'General Arena Access'],
    description: 'Special discounted pass for early birds arriving before 8:30 PM.',
  ),
  const PassTemplate(
    id: 'tpl_reg_499',
    name: 'Regular Pass',
    type: 'REGULAR',
    price: 499.0,
    defaultQuantity: 500,
    maxPerCustomer: 5,
    benefits: ['General Entry', 'Dance Floor Access'],
    description: 'Standard single entry pass with dance arena access.',
  ),
  const PassTemplate(
    id: 'tpl_fem_299',
    name: 'Female Pass',
    type: 'REGULAR',
    price: 299.0,
    defaultQuantity: 300,
    maxPerCustomer: 5,
    benefits: ['Special Female Entry', 'Safe Family Zone Access'],
    description: 'Dedicated discounted pass for female attendees with secure entry.',
  ),
  const PassTemplate(
    id: 'tpl_male_599',
    name: 'Male Stag Pass',
    type: 'REGULAR',
    price: 599.0,
    defaultQuantity: 200,
    maxPerCustomer: 4,
    benefits: ['Single Male Entry', 'General Arena Access'],
    description: 'Single male attendee general access pass.',
  ),
  const PassTemplate(
    id: 'tpl_vip_999',
    name: 'VIP Pass',
    type: 'VIP',
    price: 999.0,
    defaultQuantity: 150,
    maxPerCustomer: 4,
    benefits: ['VIP Arena Access', 'Complimentary Beverage', 'Priority Gate Entry'],
    description: 'Elevated VIP view with fast-track entry and complimentary refreshments.',
  ),
  const PassTemplate(
    id: 'tpl_cpl_1499',
    name: 'Couple Pass',
    type: 'COUPLE',
    price: 1499.0,
    defaultQuantity: 100,
    maxPerCustomer: 2,
    benefits: ['1 Couple Entry (1 Female + 1 Male)', 'Dance Floor Access'],
    description: 'Combined entry for 1 couple.',
  ),
  const PassTemplate(
    id: 'tpl_vvip_1999',
    name: 'VVIP Dome Pass',
    type: 'VVIP',
    price: 1999.0,
    defaultQuantity: 50,
    maxPerCustomer: 4,
    benefits: ['Front Stage Access', 'Dedicated AC Lounge', 'Valet Parking'],
    description: 'Exclusive front-row stage view with lounge access and valet parking.',
  ),
  const PassTemplate(
    id: 'tpl_stu_349',
    name: 'Student Pass',
    type: 'EARLY_BIRD',
    price: 349.0,
    defaultQuantity: 150,
    maxPerCustomer: 2,
    benefits: ['Valid Student ID Required', 'General Entry'],
    description: 'Concession pass for college and university students.',
  ),
  const PassTemplate(
    id: 'tpl_season_3499',
    name: 'Season All-Nights Pass',
    type: 'GROUP',
    price: 3499.0,
    defaultQuantity: 50,
    maxPerCustomer: 2,
    benefits: ['Access to All Event Nights', 'Guaranteed Express Entry'],
    description: 'All-inclusive pass valid for every night of the festival.',
  ),
  const PassTemplate(
    id: 'tpl_tbl_9999',
    name: 'VIP Lounge Table (6 Pax)',
    type: 'CUSTOM',
    price: 9999.0,
    defaultQuantity: 10,
    maxPerCustomer: 1,
    benefits: ['Reserved Table for 6', 'Food & Beverage Hamper', 'Valet Parking'],
    description: 'Private reserved hospitality table for groups of 6.',
  ),
];

class PassTemplatesNotifier extends StateNotifier<List<PassTemplate>> {
  PassTemplatesNotifier() : super(defaultPassTemplates) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(key: _kPassTemplatesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List;
        final list = decoded.map((e) => PassTemplate.fromJson(e as Map<String, dynamic>)).toList();
        if (list.isNotEmpty) {
          state = list;
        }
      }
    } catch (_) {
      // Fallback to default templates
    }
  }

  Future<void> _persist() async {
    try {
      final encoded = jsonEncode(state.map((t) => t.toJson()).toList());
      await _storage.write(key: _kPassTemplatesStorageKey, value: encoded);
    } catch (_) {}
  }

  Future<void> addTemplate(PassTemplate template) async {
    state = [...state, template];
    await _persist();
  }

  Future<void> updateTemplate(PassTemplate template) async {
    state = [
      for (final t in state)
        if (t.id == template.id) template else t,
    ];
    await _persist();
  }

  Future<void> deleteTemplate(String id) async {
    state = state.where((t) => t.id != id).toList();
    await _persist();
  }

  Future<void> resetToDefaults() async {
    state = defaultPassTemplates;
    await _persist();
  }
}

final passTemplatesProvider = StateNotifierProvider<PassTemplatesNotifier, List<PassTemplate>>((ref) {
  return PassTemplatesNotifier();
});

const _kPassCategoriesStorageKey = 'vmn_pass_categories_v1';

const defaultPassCategories = <String>[
  'REGULAR',
  'VIP',
  'VVIP',
  'COUPLE',
  'GROUP',
  'EARLY_BIRD',
  'FANPIT',
  'DIAMOND',
  'GOLD',
  'PLATINUM',
  'STUDENT',
  'FEMALE',
  'MALE_STAG',
  'VIP_TABLE',
  'SEASON_PASS',
  'CUSTOM',
];

class PassCategoriesNotifier extends StateNotifier<List<String>> {
  PassCategoriesNotifier() : super(defaultPassCategories) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _storage.read(key: _kPassCategoriesStorageKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = (jsonDecode(raw) as List).cast<String>();
        if (decoded.isNotEmpty) {
          final merged = {...defaultPassCategories, ...decoded}.toList();
          state = merged;
        }
      }
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      await _storage.write(key: _kPassCategoriesStorageKey, value: jsonEncode(state));
    } catch (_) {}
  }

  Future<void> addCategory(String category) async {
    final clean = category.trim().toUpperCase().replaceAll(' ', '_');
    if (clean.isEmpty || state.contains(clean)) return;
    state = [...state, clean];
    await _persist();
  }

  Future<void> deleteCategory(String category) async {
    state = state.where((c) => c != category).toList();
    await _persist();
  }

  Future<void> resetCategories() async {
    state = defaultPassCategories;
    await _persist();
  }
}

final passCategoriesProvider = StateNotifierProvider<PassCategoriesNotifier, List<String>>((ref) {
  return PassCategoriesNotifier();
});
