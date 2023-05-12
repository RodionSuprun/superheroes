import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/action_button.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final MainBloc bloc = MainBloc();

  @override
  Widget build(BuildContext context) {
    return Provider.value(
      value: bloc,
      child: const Scaffold(
        backgroundColor: SuperheroesColors.background,
        body: SafeArea(
          child: MainPageContent(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    bloc.dispose();
    super.dispose();
  }
}

class MainPageContent extends StatelessWidget {
  const MainPageContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context);
    return Stack(
      children: [
        const MainPageStateWidget(),
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: ActionButton(
              text: "Next state",
              onTap: () {
                bloc.nextState();
              },
            ),
          ),
        )
      ],
    );
  }
}

class MainPageStateWidget extends StatelessWidget {
  const MainPageStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context);
    return StreamBuilder<MainPageState>(
      stream: bloc.observeMainPageState(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox();
        } else {
          final MainPageState state = snapshot.data!;

          switch (state) {
            case MainPageState.loading:
              return const LoadingIndicator();
            case MainPageState.minSymbols:
              return const MinSymbolsWidget();
            case MainPageState.noFavorites:
              return const InfoWithButton(
                  title: "No favorites yet",
                  subtitle: "Search and add",
                  buttonText: "Search",
                  assetImage: SuperheroesImages.ironmanImage,
                  imageHeight: 119,
                  imageWidth: 108,
                  imageTopPadding: 9);
            case MainPageState.favorites:
              return const FavouritesWidget();
            case MainPageState.searchResult:
              return const SearchResultWidget();
            case MainPageState.nothingFound:
              return const InfoWithButton(
                  title: "Nothing found",
                  subtitle: "Search for something else",
                  buttonText: "Search",
                  assetImage: SuperheroesImages.hulkImage,
                  imageHeight: 112,
                  imageWidth: 84,
                  imageTopPadding: 16);
            case MainPageState.loadingError:
              return const InfoWithButton(
                  title: "Error happened",
                  subtitle: "Please, try again",
                  buttonText: "Retry",
                  assetImage: SuperheroesImages.supermanImage,
                  imageHeight: 106,
                  imageWidth: 126,
                  imageTopPadding: 22);
            default:
              return Center(
                child: Text(
                  state.toString(),
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                ),
              );
          }
        }
      },
    );
  }
}

class SearchResultWidget extends StatelessWidget {
  const SearchResultWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 90,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Search results",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
            name: "Batman",
            realName: "Bruce Wayne",
            imageUrl:
                "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SuperheroPage(name: "Batman"),
              ));
            },
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
              name: "Venom",
              realName: "Eddie Brock",
              imageUrl:
                  "https://www.superherodb.com/pictures2/portraits/10/100/22.jpg",
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const SuperheroPage(name: "Venom"),
                ));
              }),
        ),
      ],
    );
  }
}

class FavouritesWidget extends StatelessWidget {
  const FavouritesWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 90,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Your favorites",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
            name: "Batman",
            realName: "Bruce Wayne",
            imageUrl:
                "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SuperheroPage(name: "Batman"),
              ));
            },
          ),
        ),
        const SizedBox(
          height: 8,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SuperheroCard(
            name: "Ironman",
            realName: "Tony Stark",
            imageUrl:
                "https://www.superherodb.com/pictures2/portraits/10/100/85.jpg",
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const SuperheroPage(name: "Ironman"),
              ));
            },
          ),
        ),
      ],
    );
  }
}

class MinSymbolsWidget extends StatelessWidget {
  const MinSymbolsWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110),
        child: Text(
          "Enter at least 3 symbols",
          style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }
}

class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: EdgeInsets.only(top: 110),
        child: CircularProgressIndicator(
          color: SuperheroesColors.blue,
          strokeWidth: 4,
        ),
      ),
    );
  }
}
