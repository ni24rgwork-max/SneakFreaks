import 'package:flutter/material.dart';

import 'package:sneakers_app/view/bag/widget/body.dart';

class MyBagScreen extends StatelessWidget {
  const MyBagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      child: Scaffold(body: BodyBagView()),
    );
  }
}
