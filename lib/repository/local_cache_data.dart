import 'dart:async';

import 'package:quiet/model/playlist_detail.dart';
import 'package:flutter/foundation.dart';
import 'package:sembast/sembast.dart';

import 'database.dart';

LocalData neteaseLocalData = LocalData._();

class LocalData {
  ///netData 类型必须是可以放入 [store] 中的类型
  static Stream<T> withData<T>(String key, Future<T> netData,
      {void onNetError(dynamic e)}) async* {
    final data = neteaseLocalData[key];
    if (data != null) {
      final cached = await data;
      if (cached != null) {
        assert(cached is T, "local espect be $T, but is $cached");
        yield cached;
      }
    }
    try {
      final net = await netData;
      neteaseLocalData[key] = net;
      yield net;
    } catch (e) {
      if (onNetError != null) onNetError("$e");
      debugPrint(e);
    }
  }

  LocalData._();

  FutureOr operator [](key) async {
    return get(key);
  }

  void operator []=(key, value) {
    _put(value, key);
  }

  Future<T> get<T>(dynamic key) async {
    final Database db = await getApplicationDatabase();
    final dynamic result = StoreRef.main().record(key).get(db);
    if (result is T) {
      return result;
    }
    assert(false, "the result of $key is not subtype of $T");
    return null;
  }

  Future _put(dynamic value, [dynamic key]) async {
    final Database db = await getApplicationDatabase();
    return StoreRef.main().record(key).put(db, value);
  }

  Future<List<PlaylistDetail>> getUserPlaylist(int userId) async {
    final data = await get("user_playlist_$userId");
    if (data == null) {
      return null;
    }
    final result = (data as List)
        .cast<Map>()
        .map((m) => PlaylistDetail.fromMap(m))
        .toList();
    return result;
  }

  void updateUserPlaylist(int userId, List<PlaylistDetail> list) {
    _put(list.map((p) => p.toMap()).toList(), "user_playlist_$userId");
  }

  Future<PlaylistDetail> getPlaylistDetail(int playlistId) async {
    final data = await get("playlist_detail_$playlistId");
    return PlaylistDetail.fromMap(data);
  }

  //TODO 添加分页加载逻辑
  Future updatePlaylistDetail(PlaylistDetail playlistDetail) {
    return _put(playlistDetail.toMap(), 'playlist_detail_${playlistDetail.id}');
  }
}
