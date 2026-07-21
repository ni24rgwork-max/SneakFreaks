import 'package:flutter/material.dart';

import '../models/models.dart';
import '../utils/money.dart';

final List<ShoeModel> availableShoes = [
  ShoeModel(
    id: "sku-001",
    name: "NIKE",
    model: "AIR-MAX",
    price: Money.rupees(12995),
    mrp: Money.rupees(16995),
    imgAddress: "assets/images/nike1.png",
    modelColor: const Color(0xffDE0106),
    isNew: true,
    tags: const ['monsoon', 'running'],
  ),
  ShoeModel(
    id: "sku-002",
    name: "JORDAN",
    model: "AIR-JORDAN MID",
    price: Money.rupees(12795),
    mrp: Money.rupees(15995),
    imgAddress: "assets/images/nike8.png",
    modelColor: const Color(0xff3F7943),
    isNew: true,
    tags: const ['court'],
  ),
  ShoeModel(
    id: "sku-003",
    name: "NIKE",
    model: "ZOOM",
    price: Money.rupees(10995),
    mrp: Money.rupees(13995),
    imgAddress: "assets/images/nike2.png",
    modelColor: const Color(0xffE66863),
    tags: const ['running'],
  ),
  ShoeModel(
    id: "sku-004",
    name: "NIKE",
    model: "Air-FORCE",
    price: Money.rupees(8995),
    mrp: Money.rupees(10995),
    imgAddress: "assets/images/nike3.png",
    modelColor: const Color(0xffD7D8DC),
    tags: const ['lifestyle'],
  ),
  ShoeModel(
    id: "sku-005",
    name: "JORDAN",
    model: "AIR-JORDAN LOW",
    price: Money.rupees(12795),
    imgAddress: "assets/images/nike5.png",
    modelColor: const Color(0xff37376B),
    isNew: true,
    tags: const ['court', 'lifestyle'],
  ),
  ShoeModel(
    id: "sku-006",
    name: "NIKE",
    model: "ZOOM",
    price: Money.rupees(10995),
    mrp: Money.rupees(13995),
    imgAddress: "assets/images/nike4.png",
    modelColor: const Color(0xffE4E3E8),
    tags: const ['monsoon', 'running'],
  ),
  ShoeModel(
    id: "sku-007",
    name: "JORDAN",
    model: "AIR-JORDAN LOW",
    price: Money.rupees(12795),
    imgAddress: "assets/images/nike7.png",
    modelColor: const Color(0xffD68043),
    tags: const ['court'],
  ),
  ShoeModel(
    id: "sku-008",
    name: "JORDAN",
    model: "AIR-JORDAN LOW",
    price: Money.rupees(12795),
    imgAddress: "assets/images/nike6.png",
    modelColor: const Color(0xffE2E3E5),
    isNew: true,
    tags: const ['lifestyle', 'monsoon'],
  ),
];

final List<UserStatus> userStatus = [
  UserStatus(
    emoji: '😴',
    txt: "Away",
    selectColor: const Color(0xff121212),
    unSelectColor: const Color(0xffbfbfbf),
  ),
  UserStatus(
    emoji: '💻',
    txt: "At Work",
    selectColor: const Color(0xff05a35c),
    unSelectColor: const Color(0xffCEEBD9),
  ),
  UserStatus(
    emoji: '🎮',
    txt: "Gaming",
    selectColor: const Color(0xffFFD237),
    unSelectColor: const Color(0xffFDDFBB),
  ),
  UserStatus(
    emoji: '🤫',
    txt: "Busy",
    selectColor: const Color(0xffba3a3a),
    unSelectColor: const Color(0xffdb9797),
  ),
];

final List featured = [
  'New',
  'Featured',
  'Upcoming',
];

final List<double> sizes = [6, 7.5, 8, 9.5];
