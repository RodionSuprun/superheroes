import 'dart:async';

import 'package:rxdart/rxdart.dart';

class MainBloc {
  static const minSymbols = 3;

  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();

  final favouriteSuperherosSubject =
      BehaviorSubject<List<SuperheroInfo>>.seeded(SuperheroInfo.mocked);

  final searchedSuperherosSubject = BehaviorSubject<List<SuperheroInfo>>();

  final currentTextSubject = BehaviorSubject<String>.seeded("");

  StreamSubscription? textSubscription;
  StreamSubscription? searchSubscription;
  StreamSubscription? favouriteSubscription;

  Stream<MainPageState> observeMainPageState() {
    return stateSubject;
  }

  MainBloc() {
    stateSubject.add(MainPageState.noFavorites);
    textSubscription =
        Rx.combineLatest2<String, List<SuperheroInfo>, MainPageStateInfo>(
      currentTextSubject
          .distinct()
          .debounceTime(const Duration(milliseconds: 500)),
      favouriteSuperherosSubject,
      (searchedText, favorites) => MainPageStateInfo(
          searchText: searchedText, haveFavorites: favorites.isNotEmpty),
    ).listen((value) {
      print("Changed $value");
      searchSubscription?.cancel();
      if (value.searchText.isEmpty) {
        if (value.haveFavorites) {
          stateSubject.add(MainPageState.favorites);
        } else {
          stateSubject.add(MainPageState.noFavorites);
        }
      } else if (value.searchText.length < minSymbols) {
        stateSubject.add(MainPageState.minSymbols);
      } else {
        searchForSuperheroes(value.searchText);
      }
    });
  }

  void searchForSuperheroes(final String text) {
    stateSubject.add(MainPageState.loading);
    searchSubscription = search(text).asStream().listen((searchResults) {
      if (searchResults.isEmpty) {
        stateSubject.add(MainPageState.nothingFound);
      } else {
        searchedSuperherosSubject.add(searchResults);
        stateSubject.add(MainPageState.searchResult);
      }
    }, onError: (error, stackTrace) {
      stateSubject.add(MainPageState.loadingError);
    });
  }

  Stream<List<SuperheroInfo>> observeFavouriteSuperhero() =>
      favouriteSuperherosSubject;

  Stream<List<SuperheroInfo>> observeSearchedSuperhero() =>
      searchedSuperherosSubject;

  Future<List<SuperheroInfo>> search(final String text) async {
    await Future.delayed(const Duration(seconds: 1));
    List<SuperheroInfo> list = SuperheroInfo.mocked.where((element) {
      return element.name.toLowerCase().contains(text.toLowerCase());
    }).toList();
    return list;
  }

  void nextState() {
    final currentState = stateSubject.value;
    final nextState = MainPageState.values[
        (MainPageState.values.indexOf(currentState) + 1) %
            MainPageState.values.length];
    stateSubject.add(nextState);
  }

  void updateText(final String? text) {
    currentTextSubject.add(text ?? "");
  }

  void removeFavorite() {

    if (favouriteSuperherosSubject.value.isEmpty) {
      favouriteSuperherosSubject.add(SuperheroInfo.mocked);
    } else {
      List<SuperheroInfo> list = favouriteSuperherosSubject.value.toList();
      list.removeLast();
      favouriteSuperherosSubject.add(list);
    }
    // favouriteSubscription = favouriteSuperherosSubject.listen((value) {
    //     if (value.isEmpty) {
    //       favouriteSuperherosSubject.add(SuperheroInfo.mocked);
    //     } else {
    //       List<SuperheroInfo> list = value.toList();
    //       list.removeLast();
    //       favouriteSuperherosSubject.add(list);
    //     }
    //     favouriteSubscription?.cancel();
    // });
  }

  void dispose() {
    stateSubject.close();
    favouriteSuperherosSubject.close();
    searchedSuperherosSubject.close();
    currentTextSubject.close();
    textSubscription?.cancel();
    searchSubscription?.cancel();
    favouriteSubscription?.cancel();
  }
}

enum MainPageState {
  noFavorites,
  minSymbols,
  loading,
  nothingFound,
  loadingError,
  searchResult,
  favorites
}

class SuperheroInfo {
  final String name;
  final String realName;
  final String imageUrl;

  const SuperheroInfo(
      {required this.name, required this.realName, required this.imageUrl});

  @override
  String toString() {
    return 'SuperheroInfo{name: $name, realName: $realName, imageUrl: $imageUrl}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl;

  @override
  int get hashCode => name.hashCode ^ realName.hashCode ^ imageUrl.hashCode;

  static const mocked = [
    SuperheroInfo(
        name: "Batman",
        realName: "Bruce Wayne",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/639.jpg"),
    SuperheroInfo(
        name: "Ironman",
        realName: "Tony Stark",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/85.jpg"),
    SuperheroInfo(
        name: "Venom",
        realName: "Eddie Brock",
        imageUrl:
            "https://www.superherodb.com/pictures2/portraits/10/100/22.jpg")
  ];
}

class MainPageStateInfo {
  final String searchText;
  final bool haveFavorites;

  const MainPageStateInfo(
      {required this.searchText, required this.haveFavorites});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MainPageStateInfo &&
          runtimeType == other.runtimeType &&
          searchText == other.searchText &&
          haveFavorites == other.haveFavorites;

  @override
  int get hashCode => searchText.hashCode ^ haveFavorites.hashCode;

  @override
  String toString() {
    return 'MainPageStateInfo{searchText: $searchText, haveFavorites: $haveFavorites}';
  }
}
