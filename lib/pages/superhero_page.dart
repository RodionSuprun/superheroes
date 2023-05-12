import 'package:flutter/material.dart';

import '../resources/superheroes_colors.dart';
import '../widgets/action_button.dart';

class SuperheroPage extends StatelessWidget {
  final String name;
  const SuperheroPage({Key? key, required this.name}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SuperheroesColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  color: Colors.white,
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: ActionButton(text: "Back", onTap: () {
                  Navigator.of(context).pop();
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
