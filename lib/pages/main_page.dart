import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:superheroes/blocs/main_bloc.dart';
import 'package:superheroes/pages/superhero_page.dart';
import 'package:superheroes/resources/superheroes_colors.dart';
import 'package:superheroes/resources/superheroes_images.dart';
import 'package:superheroes/widgets/info_with_button.dart';
import 'package:superheroes/widgets/superhero_card.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  final http.Client? client;

  const MainPage({Key? key, this.client}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late MainBloc bloc;

  @override
  void initState() {
    super.initState();
    bloc = MainBloc(client: widget.client);
  }

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
    return const Stack(
      children: [
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

  bool haveSearchedText = false;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
      final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);
      bloc.observeRequestFocus().listen((event) {
        if (event == true) {
          focusNode.requestFocus();
        }
      });
      controller.addListener(() {
        bloc.updateText(controller.text);
        final haveText = controller.text.isNotEmpty;
        if (haveSearchedText != haveText) {
          setState(() {
            haveSearchedText = haveText;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      focusNode: focusNode,
      controller: controller,
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
          borderSide: haveSearchedText
              ? const BorderSide(color: Colors.white, width: 2)
              : const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
    );
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
              return InfoWithButton(
                title: "No favorites yet",
                subtitle: "Search and add",
                buttonText: "Search",
                assetImage: SuperheroesImages.ironmanImage,
                imageHeight: 119,
                imageWidth: 108,
                imageTopPadding: 9,
                onTap: () {
                  bloc.requestFocus();
                },
              );
            case MainPageState.favorites:
              return SuperheroesList(
                title: "Your favourites",
                stream: bloc.observeFavouriteSuperhero(),
                ableToSwipe: true,
              );
            case MainPageState.searchResult:
              return SuperheroesList(
                title: "Search results",
                stream: bloc.observeSearchedSuperhero(),
                ableToSwipe: false,
              );
            case MainPageState.nothingFound:
              return InfoWithButton(
                title: "Nothing found",
                subtitle: "Search for something else",
                buttonText: "Search",
                assetImage: SuperheroesImages.hulkImage,
                imageHeight: 112,
                imageWidth: 84,
                imageTopPadding: 16,
                onTap: () {
                  bloc.requestFocus();
                },
              );
            case MainPageState.loadingError:
              return InfoWithButton(
                title: "Error happened",
                subtitle: "Please, try again",
                buttonText: "Retry",
                assetImage: SuperheroesImages.supermanImage,
                imageHeight: 106,
                imageWidth: 126,
                imageTopPadding: 22,
                onTap: () {
                  bloc.retry();
                },
              );
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
  final bool ableToSwipe;

  const SuperheroesList(
      {Key? key,
      required this.title,
      required this.stream,
      required this.ableToSwipe})
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
                return ListTitleWidget(title: title);
              } else {
                final SuperheroInfo item = superheroes[index - 1];
                return ListTile(
                  superhero: item,
                  ableToSwipe: ableToSwipe,
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

class ListTile extends StatelessWidget {
  final bool ableToSwipe;

  const ListTile({
    Key? key,
    required this.superhero,
    required this.ableToSwipe,
  }) : super(key: key);

  final SuperheroInfo superhero;

  @override
  Widget build(BuildContext context) {
    final MainBloc bloc = Provider.of<MainBloc>(context, listen: false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ableToSwipe == true
          ? Dismissible(
              key: ValueKey(superhero.id),
              child: SuperheroCard(
                superheroInfo: superhero,
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => SuperheroPage(id: superhero.id),
                  ));
                },
              ),
              background: Container(
                height: 70,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: SuperheroesColors.red,
                ),
                child: Text(
                  "Remove\nfrom\nfavorites".toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              secondaryBackground: Container(
                height: 70,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: SuperheroesColors.red,
                ),
                child: Text(
                  "Remove\nfrom\nfavorites".toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              onDismissed: (_) {
                bloc.removeFromFavorites(superhero.id);
              },
            )
          : SuperheroCard(
              superheroInfo: superhero,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => SuperheroPage(id: superhero.id),
                ));
              },
            ),
    );
  }
}

class ListTitleWidget extends StatelessWidget {
  const ListTitleWidget({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 90, left: 16, right: 16, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24),
      ),
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
