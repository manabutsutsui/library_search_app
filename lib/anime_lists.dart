class AnimeList {
  final String name;
  final String genre;
  final String imageAsset;
  final String imageUrl;

  AnimeList({
    required this.name,
    required this.genre,
    required this.imageAsset,
    required this.imageUrl,
  });
}

final List<AnimeList> animeList = [
  AnimeList(
    name: '君の名は。',
    genre: '映画',
    imageAsset: 'assets/images/your_name.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=21670',
  ),
  AnimeList(
    name: 'ハイキュー!!',
    genre: 'スポーツ/競技',
    imageAsset: 'assets/images/haikyuu.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=23182',
  ),
  AnimeList(
    name: 'その着せ替え人形は恋をする',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/kisekoi.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=25202',
  ),
  AnimeList(
    name: '五等分の花嫁',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/gotoubunn.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=26577',
  ),
  AnimeList(
    name: 'SLAM DUNK',
    genre: 'スポーツ/競技',
    imageAsset: 'assets/images/slumdunk.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10774',
  ),
  AnimeList(
    name: 'あの日見た花の名前を僕達はまだ知らない。',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/anohana.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=11171',
  ),
  AnimeList(
    name: 'ぼっちざろっく',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/bocchi.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=25806',
  ),
  AnimeList(
    name: '天気の子',
    genre: '映画',
    imageAsset: 'assets/images/tennkinoko.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=23967',
  ),
  AnimeList(
    name: '鬼滅の刃',
    genre: 'アクション/バトル',
    imageAsset: 'assets/images/kimetu.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=22675',
  ),
  AnimeList(
    name: '四月は君の嘘',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/shigatsuha.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=11513',
  ),
  AnimeList(
    name: '言の葉の庭',
    genre: '映画',
    imageAsset: 'assets/images/kotonoha.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=11418',
  ),
  AnimeList(
    name: 'スキップとローファー',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/skip.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=26254',
  ),
  AnimeList(
    name: '氷菓',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/hyoka.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10838',
  ),
  AnimeList(
    name: '聲の形',
    genre: '映画',
    imageAsset: 'assets/images/koenokatachi.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=22155',
  ),
  AnimeList(
    name: 'リコリス・リコイル',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/rikorisu.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=25620',
  ),
  AnimeList(
    name: 'ひぐらしのなく頃に',
    genre: 'ホラー/サスペンス/推理',
    imageAsset: 'assets/images/higurashi.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10954',
  ),
  AnimeList(
    name: '涼宮ハルヒの憂鬱',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/haruhi.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10853',
  ),
  AnimeList(
    name: '秒速5センチメートル',
    genre: '映画',
    imageAsset: 'assets/images/byosoku.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10677',
  ),
  AnimeList(
    name: '花咲くいろは',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/hanasaku.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10768',
  ),
  AnimeList(
    name: 'ラブライブ！',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/lovelive.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=11141',
  ),
  AnimeList(
    name: 'サマータイムレンダ',
    genre: 'ホラー/サスペンス/推理',
    imageAsset: 'assets/images/summertime.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=25892',
  ),
  AnimeList(
    name: '艦隊これくしょん',
    genre: 'アクション/バトル',
    imageAsset: 'assets/images/kankore.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=25861',
  ),
  AnimeList(
    name: '夏目友人帳',
    genre: 'ホラー/サスペンス/推理',
    imageAsset: 'assets/images/natsume.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10847',
  ),
  AnimeList(
    name: 'すずめの戸締まり',
    genre: '映画',
    imageAsset: 'assets/images/suzumeno.jpg',
    imageUrl: 'https://www.netflix.com/jp/title/81696498',
  ),
  AnimeList(
    name: 'サマーウォーズ',
    genre: '映画',
    imageAsset: 'assets/images/summerwars.png',
    imageUrl: 'https://s-wars.jp/special/images/SW-Wallpaper1-HD.jpg',
  ),
  AnimeList(
    name: 'らき☆すた',
    genre: '日常/ほのぼの',
    imageAsset: 'assets/images/rakisuta.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10338',
  ),
  AnimeList(
    name: '千と千尋の神隠し',
    genre: '映画',
    imageAsset: 'assets/images/sentochihiro.png',
    imageUrl: 'https://www.ghibli.jp/works/chihiro/',
  ),
  AnimeList(
    name: 'ガールズ&パンツァー',
    genre: 'アクション/バトル',
    imageAsset: 'assets/images/girlsand.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=27105',
  ),
  AnimeList(
    name: 'となりのトトロ',
    genre: '映画',
    imageAsset: 'assets/images/tonarinototoro.png',
    imageUrl: 'https://www.youtube.com/watch?v=S2AdSjrG5iM',
  ),
  AnimeList(
    name: '響け！ユーフォニアム',
    genre: 'ドラマ/青春',
    imageAsset: 'assets/images/hibike.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=20098',
  ),
  AnimeList(
    name: 'ゆるキャン△',
    genre: '日常/ほのぼの',
    imageAsset: 'assets/images/yurukyan.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=21928',
  ),
  AnimeList(
    name: 'やはり俺の青春ラブコメはまちがっている。',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/oregairu.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=22967',
  ),
  AnimeList(
    name: '僕のヒーローアカデミア',
    genre: 'アクション/バトル',
    imageAsset: 'assets/images/my_hero.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=20868',
  ),
  AnimeList(
    name: '君に届け',
    genre: 'ドラマ/青春',
    imageAsset: 'assets/images/kiminitodoke.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=21219',
  ),
  AnimeList(
    name: 'もののけ姫',
    genre: '映画',
    imageAsset: 'assets/images/mononoke.png',
    imageUrl: 'https://www.ghibli.jp/works/mononoke/',
  ),
  AnimeList(
    name: '呪術廻戦',
    genre: 'アクション/バトル',
    imageAsset: 'assets/images/jujutsu.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=26467',
  ),
  AnimeList(
    name: '弱虫ペダル',
    genre: 'スポーツ/競技',
    imageAsset: 'assets/images/yowamushi.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=11443',
  ),
  AnimeList(
    name: 'STEINS;GATE',
    genre: 'SF/ファンタジー',
    imageAsset: 'assets/images/syutage.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10693',
  ),
  AnimeList(
    name: 'りゅうおうのおしごと！',
    genre: 'スポーツ/競技',
    imageAsset: 'assets/images/ryuono.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=21953',
  ),
  AnimeList(
    name: '僕の心のヤバイやつ',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/bokunokokoro.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=27390',
  ),
  AnimeList(
    name: '青春ブタ野郎はバニーガール先輩の夢を見ない',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/aobuta.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=22406',
  ),
  AnimeList(
    name: '俺の妹がこんなに可愛いわけがない',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/oreimo.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=10642',
  ),
  AnimeList(
    name: '暗殺教室',
    genre: 'アクション/バトル',
    imageAsset: 'assets/images/ansatu.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=11612',
  ),
  AnimeList(
    name: '冴えない彼女の育てかた',
    genre: '恋愛/ラブコメ',
    imageAsset: 'assets/images/saekano.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=11611',
  ),
  AnimeList(
    name: 'しかのこのこのここしたんたん',
    genre: 'SF/ファンタジー',
    imageAsset: 'assets/images/shika.png',
    imageUrl: 'https://animestore.docomo.ne.jp/animestore/ci_pc?workId=27226',
  ),
];
