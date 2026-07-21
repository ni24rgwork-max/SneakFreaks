import 'package:flutter/material.dart';

import 'package:sneakers_app/data/dummy_data.dart';
import 'package:sneakers_app/widget/snack_bar.dart';

import '../models/models.dart';
import 'money.dart';

class AppMethods {
  AppMethods._();
  static void addToCart(ShoeModel data, BuildContext context) {
    bool contains = itemsOnBag.contains(data);

    if (contains == true) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(failedSnackBar(context));
    } else {
      itemsOnBag.add(data);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(successSnackBar(context));
    }
  }

  static Money sumOfItemsOnBag() {
    var sum = Money.zero;
    for (final bagModel in itemsOnBag) {
      sum += bagModel.price;
    }
    return sum;
  }
}
