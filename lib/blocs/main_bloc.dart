import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/ApiException.dart';
import 'package:superheroes/favourite_superhero_storage.dart';
import 'package:superheroes/model/superhero.dart';

import '../model/alignment_info.dart';

class MainBloc {
  static const minSymbols = 3;

  final BehaviorSubject<MainPageState> stateSubject = BehaviorSubject();

  final searchedSuperherosSubject = BehaviorSubject<List<SuperheroInfo>>();

  final currentTextSubject = BehaviorSubject<String>.seeded("");

  final requestFocusSubject = BehaviorSubject<bool>();

  StreamSubscription? textSubscription;
  StreamSubscription? searchSubscription;
  StreamSubscription? favouriteSubscription;
  StreamSubscription? removeFromFavoriteSubscription;

  http.Client? client;

  Stream<MainPageState> observeMainPageState() {
    return stateSubject;
  }

  MainBloc({this.client}) {
    stateSubject.add(MainPageState.noFavorites);
    textSubscription =
        Rx.combineLatest2<String, List<Superhero>, MainPageStateInfo>(
      currentTextSubject
          .distinct()
          .debounceTime(const Duration(milliseconds: 500)),
      FavouriteSuperheroStorage.getInstance().observeFavoriteSuperheroes(),
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
      print("RedDed ${error.toString()}");
      stateSubject.add(MainPageState.loadingError);
    });
  }

  Stream<List<SuperheroInfo>> observeFavouriteSuperhero() {
    return FavouriteSuperheroStorage.getInstance()
        .observeFavoriteSuperheroes()
        .map((superheroes) => superheroes
            .map((superhero) => SuperheroInfo.fromSuperhero(superhero))
            .toList());
  }

  void removeFromFavorites(final String id) {
    removeFromFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription = FavouriteSuperheroStorage.getInstance()
        .removeFromFavourites(id)
        .asStream()
        .listen(
      (event) {
        print("removeFromFavourite ${event.toString()}");
      },
      onError: (error, stackTrace) {
        print("removeFromFavourite error ${error.toString()}");
      },
    );
  }

  Stream<List<SuperheroInfo>> observeSearchedSuperhero() =>
      searchedSuperherosSubject;

  Stream<bool> observeRequestFocus() => requestFocusSubject;

  Future<List<SuperheroInfo>> search(final String text) async {
    final token = dotenv.env["SUPERHERO_TOKEN"];
    final response = await (client ??= http.Client())
        .get(Uri.parse("https://superheroapi.com/api/$token/search/$text"));
    final decoded = json.decode(response.body);
    if (500 <= response.statusCode && response.statusCode <= 599) {
      throw ApiException("Server error happened");
    } else if (400 <= response.statusCode && response.statusCode <= 499) {
      throw ApiException("Client error happened");
    }
    if (decoded['response'] == 'success') {
      final List<dynamic> results = decoded['results'];
      final List<Superhero> superheroes = results.map((rawSuperhero) {
        return Superhero.fromJson(rawSuperhero);
      }).toList();
      final List<SuperheroInfo> found = superheroes.map((superhero) {
        return SuperheroInfo.fromSuperhero(superhero);
      }).toList();
      return found;
    } else if (decoded['response'] == 'error') {
      if (decoded['error'] == 'character with given name not found') {
        return [];
      } else {
        throw ApiException("Client error happened");
      }
    }
    throw Exception("Unknown error happened");
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

  void requestFocus() {
    requestFocusSubject.add(true);
  }

  void retry() {
    searchForSuperheroes(currentTextSubject.value);
  }

  void dispose() {
    stateSubject.close();
    searchedSuperherosSubject.close();
    requestFocusSubject.close();
    currentTextSubject.close();
    textSubscription?.cancel();
    searchSubscription?.cancel();
    removeFromFavoriteSubscription?.cancel();
    favouriteSubscription?.cancel();
    client?.close();
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
  final String id;
  final String name;
  final String realName;
  final String imageUrl;
  final AlignmentInfo? alignmentInfo;

  const SuperheroInfo(
      {required this.id,
      required this.name,
      required this.realName,
      required this.imageUrl,
      required this.alignmentInfo});

  factory SuperheroInfo.fromSuperhero(Superhero superhero) {
    return SuperheroInfo(
      id: superhero.id,
      name: superhero.name,
      realName: superhero.biography.fullName,
      imageUrl: superhero.image.url,
      alignmentInfo: superhero.biography.alignmentInfo,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SuperheroInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          realName == other.realName &&
          imageUrl == other.imageUrl &&
          alignmentInfo == other.alignmentInfo;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      realName.hashCode ^
      imageUrl.hashCode ^
      alignmentInfo.hashCode;

  @override
  String toString() {
    return 'SuperheroInfo{id: $id, name: $name, realName: $realName, imageUrl: $imageUrl, alignmentInfo: $alignmentInfo}';
  }
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
