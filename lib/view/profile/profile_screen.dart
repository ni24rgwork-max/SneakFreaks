import 'package:flutter/material.dart';

import 'package:sneakers_app/view/profile/widget/appbar.dart';
import 'package:sneakers_app/view/profile/widget/body.dart';

class Profile extends StatelessWidget {
  const Profile({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: customAppBarProfile(context),
        body: const BodyProfile(),
      ),
    );
  }
}
