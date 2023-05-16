import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/action_button.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

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
    return Stack(
      children: const [
        MainPageStateWidget(),
        Padding(
          padding: EdgeInsets.only(top: 12, left: 16, right: 16),
          child: SearchWidget(),
        )
      ],
    );
  }
}

class SearchWidget extends StatefulWidget {
  const SearchWidget({
    Key? key,
  }) : super(key: key);

  @override
  State<SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<SearchWidget> {
  final TextEditingController controller = TextEditingController();
  final FocusNode focusNode = FocusNode();

  BorderSide white24BorderSide = const BorderSide(color: Colors.white24);
  BorderSide whiteBorderSide = const BorderSide(color: Colors.white, width: 2);
  BorderSide borderSide = const BorderSide(color: Colors.white24);

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance?.addPostFrameCallback((timeStamp) {
      final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
      controller.addListener(() {
        bloc.updateText(controller.text);
        if (!focusNode.hasFocus && controller.text.isEmpty) {
          setState(() {
            borderSide = const BorderSide(color: Colors.white24);
          });
        }
      });
    });

    focusNode.addListener(() {
      if (!focusNode.hasFocus) {

          if (controller.text.isNotEmpty) {
            if (borderSide != whiteBorderSide) {
              setState(() {
                borderSide = const BorderSide(color: Colors.white, width: 2);
              });
            }
          } else {
            if (borderSide != white24BorderSide) {
              setState(() {
                borderSide = const BorderSide(color: Colors.white24);
              });
            }

          }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      cursorColor: Colors.white,
      textInputAction: TextInputAction.search,
      textCapitalization: TextCapitalization.words,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: SuperheroesColors.indigo75,
        prefixIcon: const Icon(
          Icons.search,
          color: Colors.white54,
          size: 24,
        ),
        suffix: GestureDetector(
          onTap: () {
            controller.clear();
          },
          child: const Icon(
            Icons.clear,
            color: Colors.white,
          ),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: borderSide,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }
}

class MainPageStateWidget extends StatelessWidget {
  const MainPageStateWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
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
              return Stack(
                children: [
                  const InfoWithButton(
                      title: "No favorites yet",
                      subtitle: "Search and add",
                      buttonText: "Search",
                      assetImage: SuperheroesImages.ironmanImage,
                      imageHeight: 119,
                      imageWidth: 108,
                      imageTopPadding: 9),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ActionButton(
                          text: "Remove",
                          onTap: () {
                            bloc.removeFavorite();
                          }),
                    ),
                  ),
                ],
              );
            case MainPageState.favorites:
              return Stack(
                children: [
                  SuperheroesList(
                    title: "Your favourites",
                    stream: bloc.observeFavouriteSuperhero(),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ActionButton(
                          text: "Remove",
                          onTap: () {
                            bloc.removeFavorite();
                          }),
                    ),
                  )
                ],
              );
            case MainPageState.searchResult:
              return SuperheroesList(
                title: "Search results",
                stream: bloc.observeSearchedSuperhero(),
              );
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

class SuperheroesList extends StatelessWidget {
  final String title;
  final Stream<List<SuperheroInfo>> stream;

  const SuperheroesList({Key? key, required this.title, required this.stream})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SuperheroInfo>>(
        stream: stream,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data == null) {
            return const SizedBox.shrink();
          }
          final List<SuperheroInfo> superheroes = snapshot.data!;
          return ListView.separated(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            itemCount: superheroes.length + 1,
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(
                      top: 90, left: 16, right: 16, bottom: 12),
                  child: Text(
                    title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 24),
                  ),
                );
              } else {
                final SuperheroInfo item = superheroes[index - 1];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SuperheroCard(
                    superheroInfo: item,
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => SuperheroPage(name: item.name),
                      ));
                    },
                  ),
                );
              }
            },
            separatorBuilder: (BuildContext context, int index) {
              return const SizedBox(
                height: 8,
              );
            },
          );
        });
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
