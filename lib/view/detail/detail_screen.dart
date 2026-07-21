import 'package:flutter/material.dart';

import 'package:sneakers_app/models/shoe_model.dart';
import 'package:sneakers_app/view/detail/components/app_bar.dart';
import 'package:sneakers_app/view/detail/components/body.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({
    super.key,
    required this.model,
    required this.isComeFromMoreSection,
  });

  final ShoeModel model;
  final bool isComeFromMoreSection;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: customAppBarDe(context, model.name),
        body: DetailsBody(
          model: model,
          isComeFromMoreSection: isComeFromMoreSection,
        ),
      ),
    );
  }
}
