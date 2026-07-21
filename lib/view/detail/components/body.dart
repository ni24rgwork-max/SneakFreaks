// ignore_for_file: prefer_const_constructors, prefer_const_literals_to_create_immutables, sized_box_for_whitespace, must_be_immutable, use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sneakers_app/widget/add_to_bag.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../../animation/fadeanimation.dart';
import '../../../../../models/shoe_model.dart';
import '../../../data/dummy_data.dart';
import '../../../models/models.dart';
import 'package:sneakers_app/theme/app_theme.dart';
import 'package:sneakers_app/theme/typography.dart';

class DetailsBody extends ConsumerStatefulWidget {
  ShoeModel model;
  bool isComeFromMoreSection;
  DetailsBody({required this.model, required this.isComeFromMoreSection});

  @override
  ConsumerState<DetailsBody> createState() => details();
}

class details extends ConsumerState<DetailsBody> {
  bool _isSelectedCountry = false;
  int? _isSelectedSize;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Container(
      width: width,
      height: height * 1.1,
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child: Column(
          children: [
            topInformationWidget(width, height),
            middleImgListWidget(width, height),
            SizedBox(
              height: 20,
              width: width / 1.1,
              child: Divider(
                thickness: 1.4,
                color: context.colors.onSurfaceVariant,
              ),
            ),
            SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  nameAndPrice(),
                  SizedBox(height: 10),
                  shoeInfo(width, height),
                  SizedBox(
                    height: 5,
                  ),
                  moreDetailsText(width, height),
                  sizeTextAndCountry(width, height),
                  SizedBox(
                    height: 10,
                  ),
                  endSizesAndButton(width, height),
                  SizedBox(
                    height: 20,
                  ),
                  materialButton(width, height),
                  SizedBox(
                    height: 20,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // Top information Widget Components
  topInformationWidget(width, height) {
    return Container(
      width: width,
      height: height / 2.3,
      child: Stack(
        children: [
          Positioned(
            left: 50,
            bottom: 20,
            child: FadeAnimation(
              delay: 0.5,
              child: Container(
                width: 1000,
                height: height / 2.2,
                decoration: BoxDecoration(
                  color: widget.model.modelColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(1500),
                    bottomRight: Radius.circular(100),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: 30,
            child: Hero(
              tag: widget.isComeFromMoreSection
                  ? widget.model.model
                  : widget.model.imgAddress,
              child: RotationTransition(
                turns: AlwaysStoppedAnimation(-25 / 360),
                child: Container(
                  width: width / 1.3,
                  height: height / 4.3,
                  child: Image(image: AssetImage(widget.model.imgAddress)),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // Rounded Image Widget About Below method Components
  roundedImage(width, height) {
    return Container(
      padding: EdgeInsets.all(2),
      width: width / 5,
      height: height / 14,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: context.colors.surfaceContainerHigh,
      ),
      child: Image(
        image: AssetImage(widget.model.imgAddress),
      ),
    );
  }

  // Middle Image List Widget Components
  middleImgListWidget(width, height) {
    return FadeAnimation(
      delay: 0.5,
      child: Container(
        padding: EdgeInsets.all(2),
        width: width,
        height: height / 11,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            roundedImage(width, height),
            roundedImage(width, height),
            roundedImage(width, height),
            Container(
              padding: EdgeInsets.all(2),
              width: width / 5,
              height: height / 14,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHigh,
                image: DecorationImage(
                  image: AssetImage(widget.model.imgAddress),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                      Colors.grey.withOpacity(1), BlendMode.darken),
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 30,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //MaterialButton Components
  materialButton(width, height) {
    return FadeAnimation(
      delay: 3.5,
      child: MaterialButton(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        minWidth: width / 1.2,
        height: height / 15,
        color: context.colors.primary,
        onPressed: () {
          final i = _isSelectedSize;
          addToBag(
            context,
            ref,
            widget.model,
            // If a size is already chosen on the page, skip the picker.
            size: i == null ? null : widget.model.sizes[i],
          );
        },
        child: Text(
          "ADD TO BAG",
          style: context.text.labelLarge?.copyWith(color: context.colors.onPrimary),
        ),
      ),
    );
  }

  //end section Sizes And Button Components
  endSizesAndButton(width, height) {
    return Container(
      width: width,
      height: height / 14,
      child: FadeAnimation(
        delay: 3,
        child: Row(
          children: [
            Container(
              width: width / 4.5,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: context.brand.interactiveBorder, width: 1)),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Try it",
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                    SizedBox(
                      width: 8,
                    ),
                    RotatedBox(
                        quarterTurns: -1,
                        child: FaIcon(FontAwesomeIcons.shoePrints))
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 15,
            ),
            Container(
              width: width / 1.5,
              child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: widget.model.sizes.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (ctx, index) {
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _isSelectedSize = index;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(right: 5),
                        width: width / 4.4,
                        height: height / 13,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _isSelectedSize == index
                                  ? context.colors.primary
                                  : context.brand.interactiveBorder,
                              width: 1.5),
                          color: _isSelectedSize == index
                              ? context.colors.primary
                              : context.colors.surface,
                        ),
                        child: Center(
                          child: Text(
                            widget.model.sizes[index],
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _isSelectedSize == index
                                    ? context.colors.onPrimary
                                    : context.colors.onSurface),
                          ),
                        ),
                      ),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }

  //Size Text And Country Button Components
  sizeTextAndCountry(width, height) {
    return FadeAnimation(
      delay: 2.5,
      child: Row(
        children: [
          Text(
            "Size",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
              fontSize: 22,
            ),
          ),
          Expanded(
            child: Container(),
          ),
          Container(
            width: width / 9,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isSelectedCountry = false;
                });
              },
              child: Text(
                "UK",
                style: TextStyle(
                  fontWeight:
                      _isSelectedCountry ? FontWeight.w400 : FontWeight.bold,
                  color: _isSelectedCountry
                      ? Colors.grey
                      : context.colors.onSurface,
                  fontSize: 19,
                ),
              ),
            ),
          ),
          Container(
            width: width / 5,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _isSelectedCountry = true;
                });
              },
              child: Text(
                "USA",
                style: TextStyle(
                  fontWeight:
                      _isSelectedCountry ? FontWeight.bold : FontWeight.w400,
                  color: _isSelectedCountry
                      ? context.colors.onSurface
                      : Colors.grey,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  //more details Text Components
  moreDetailsText(width, height) {
    return FadeAnimation(
      delay: 2,
      child: Container(
        padding: EdgeInsets.only(right: 280),
        height: height / 26,
        child: FittedBox(
            child: Text('MORE DETAILS', style: context.text.labelLarge?.copyWith(decoration: TextDecoration.underline))),
      ),
    );
  }

  //About Shoe Text Components
  shoeInfo(width, height) {
    return FadeAnimation(
      delay: 1.5,
      child: Container(
        width: width,
        height: height / 9,
        child: Text(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Proin tincidunt laoreet enim, eget sodales ligula semper at. Sed id aliquet eros, nec vestibulum felis. Nunc maximus aliquet aliquam. Quisque eget sapien at velit cursus tincidunt. Duis tempor lacinia erat eget fermentum.",
            style: context.text.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant)),
      ),
    );
  }

  //Name And Price Text Components
  nameAndPrice() {
    return FadeAnimation(
      delay: 1,
      child: Row(
        children: [
          Text(
            widget.model.model,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: context.colors.onSurface,
            ),
          ),
          Expanded(child: Container()),
          Text(widget.model.price.formatted,
              style: context.text.titleLarge?.copyWith(fontFeatures: AppTypography.tabular)),
        ],
      ),
    );
  }
}
