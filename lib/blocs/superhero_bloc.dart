import 'dart:async';
import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:rxdart/rxdart.dart';
import 'package:http/http.dart' as http;
import 'package:superheroes/exception/ApiException.dart';
import 'package:superheroes/favourite_superhero_storage.dart';
import 'package:superheroes/model/superhero.dart';

class SuperheroBloc {
  http.Client? client;
  final String id;
  final BehaviorSubject<SuperheroPageState> stateSubject = BehaviorSubject();
  final BehaviorSubject<Superhero> superheroSubject = BehaviorSubject();
  StreamSubscription? requestSubscription;
  StreamSubscription? getFromFavoriteSubscription;
  StreamSubscription? addToFavoriteSubscription;
  StreamSubscription? removeFromFavoriteSubscription;
  StreamSubscription? updateInFavorite;
  StreamSubscription? retrySubscription;

  SuperheroBloc({required this.client, required this.id}) {
    getFromFavorites();
  }

  Stream<Superhero> observeSuperhero() => superheroSubject;

  Stream<bool> observeIsFavourite() =>
      FavouriteSuperheroStorage.getInstance().observeIsFavorite(id);

  Stream<SuperheroPageState> observeSuperheroPageState() {
    return stateSubject.distinct();
  }

  void requestSuperheroInfo() {
    final oldHero = superheroSubject.valueOrNull;
    requestSubscription = request().asStream().listen((superhero) {
      stateSubject.add(SuperheroPageState.loaded);
      if (oldHero == null) {
        superheroSubject.add(superhero);
      } else {
        if (oldHero != superhero) {
          updateHeroInFavorite(superhero);
        }
      }
    }, onError: (error, stackTrace) {
      print("RedDed ${error.toString()}");
      if (oldHero == null) {
        stateSubject.add(SuperheroPageState.error);
      }
    });
  }

  void updateHeroInFavorite(final Superhero superhero) {
    updateInFavorite?.cancel();
    updateInFavorite = FavouriteSuperheroStorage.getInstance()
        .updateInFavorite(id, superhero)
        .asStream()
        .listen((event) {
      print("updateInFavorite - ${event.toString()}");
    }, onError: (error, stackTrace) {
      print("updateInFavorite error ${error.toString()}");
    });
    superheroSubject.add(superhero);
  }

  void getFromFavorites() {
    getFromFavoriteSubscription?.cancel();
    getFromFavoriteSubscription = FavouriteSuperheroStorage.getInstance()
        .getSuperhero(id)
        .asStream()
        .listen(
      (superhero) {
        if (superhero != null) {
          stateSubject.add(SuperheroPageState.loaded);
          superheroSubject.add(superhero);
        } else {
          stateSubject.add(SuperheroPageState.loading);
        }
        requestSuperheroInfo();
      },
      onError: (error, stackTrace) {
        print("getFromFavorites error ${error.toString()}");
        requestSuperheroInfo();
      },
    );
  }

  Future<Superhero> request() async {
    final token = dotenv.env["SUPERHERO_TOKEN"];
    final response = await (client ??= http.Client())
        .get(Uri.parse("https://superheroapi.com/api/$token/$id"));
    final decoded = json.decode(response.body);
    if (500 <= response.statusCode && response.statusCode <= 599) {
      throw ApiException("Server error happened");
    } else if (400 <= response.statusCode && response.statusCode <= 499) {
      throw ApiException("Client error happened");
    }
    if (decoded['response'] == 'success') {
      return Superhero.fromJson(decoded);
    } else if (decoded['response'] == 'error') {
      throw ApiException(decoded['error']);
    }
    throw Exception("Unknown error happened");
  }

  void addToFavourite() {
    final superhero = superheroSubject.valueOrNull;
    if (superhero == null) {
      print("Error");
      return;
    }
    addToFavoriteSubscription?.cancel();

    addToFavoriteSubscription = FavouriteSuperheroStorage.getInstance()
        .addToFavourites(superhero)
        .asStream()
        .listen(
      (event) {
        print("Added to favorite ${event.toString()}");
      },
      onError: (error, stackTrace) {
        print("addToFavourite error ${error.toString()}");
      },
    );
  }

  void removeFromFavourite() {
    final superhero = superheroSubject.valueOrNull;
    if (superhero == null) {
      print("Error");
      return;
    }

    removeFromFavoriteSubscription?.cancel();

    removeFromFavoriteSubscription = FavouriteSuperheroStorage.getInstance()
        .removeFromFavourites(superhero.id)
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

  void retry() {
    stateSubject.add(SuperheroPageState.loading);
    retrySubscription?.cancel();
    retrySubscription = request().asStream().listen((superhero) {
      stateSubject.add(SuperheroPageState.loaded);
      superheroSubject.add(superhero);
    }, onError: (error, stackTrace) {
      print("retrySubscription ${error.toString()}");
      stateSubject.add(SuperheroPageState.error);
    });
  }

  void dispose() {
    superheroSubject.close();
    stateSubject.close();
    requestSubscription?.cancel();
    addToFavoriteSubscription?.cancel();
    getFromFavoriteSubscription?.cancel();
    removeFromFavoriteSubscription?.cancel();
    updateInFavorite?.cancel();
    retrySubscription?.cancel();
    client?.close();
  }
}

enum SuperheroPageState { loading, loaded, error }
