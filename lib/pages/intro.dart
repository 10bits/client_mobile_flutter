import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/Intro.dart';
import '../utils/color.dart';
import '../utils/request.dart';
import '../components/NovelItem.dart';
import '../components/LoadingView.dart';

class IntroPage extends StatefulWidget {
  final String url;
  IntroPage({this.url});

  @override
  State createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  Intro _intro;
  bool _whetherPostLoading = false;

  @override
  void initState() {
    _fetchIntroInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> content = [];

    if (_intro == null) {
      content.add(LoadingView());
    } else {
      content.add(_buildBookAndAuthor());
      content.add(_buildTimeAndClassify());
      content.add(_buildBookDesc());
      content.add(_buildFooterBtn());
    }

    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        color: MyColor.bgColor,
        child: ListView(children: content),
      ),
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      backgroundColor: MyColor.bgColor,
      elevation: 0,
      title: Text('详情页', style: TextStyle(color: MyColor.appBarTitle)),
      leading: IconButton(
        icon: Icon(Icons.chevron_left),
        color: MyColor.iconColor,
        iconSize: 32,
        onPressed: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  /* 第一行：小说名称和作者名称 */
  Widget _buildBookAndAuthor() {
    return Container(
      width: 150.0,
      height: 200.0,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.symmetric(horizontal: 130.0),
      child:
          NovelItem(authorName: _intro.authorName, bookName: _intro.bookName),
    );
  }

  /* 第二行：更新时间和分类 */
  Widget _buildTimeAndClassify() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text('更新时间：' + _intro.lastUpdateAt),
          Text('分类：' + _intro.classifyName)
        ],
      ),
    );
  }

  /* 第三行：小说简介 */
  Widget _buildBookDesc() {
    return Container(
      color: Colors.white,
      margin: EdgeInsets.symmetric(vertical: 10.0),
      padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text('简介', style: TextStyle(fontSize: 18.0)),
          ),
          Text(_intro.bookDesc, softWrap: true),
        ],
      ),
    );
  }

  /* 加入书架按钮 */
  Widget _buildFooterBtn() {
    return GestureDetector(
      child: Container(
        margin: EdgeInsets.only(top: 20.0),
        child: Text('加入书架', style: TextStyle(color: Colors.white)),
        height: 48.0,
        alignment: Alignment.center,
        color: Colors.blue,
      ),
      onTap: () {
        if (_whetherPostLoading) return
        _postShelf();
      },
    );
  }

  _fetchIntroInfo() async {
    try {
      var result = await HttpUtils.getInstance()
          .get('/gysw/novel/detail?url=${Uri.encodeComponent(widget.url)}');
      IntroModel introResult = IntroModel.fromJson(result.data);

      setState(() {
        _intro = introResult.data;
      });
    } catch (e) {
      print(e);
    }
  }

  /* 加入书架 */
  _postShelf() async {
    setState(() {
      _whetherPostLoading = true;
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    int userId = prefs.getInt('userId') ?? -1; // 取
    String token = prefs.getString('token');

    try {
      Response<Map> result = await HttpUtils.getInstance().post('/gysw/shelf',
        data: {
          'userId': userId,
          'authorName': _intro.authorName,
          'bookName': _intro.bookName,
          'bookDesc': _intro.bookDesc,
          'bookCoverUrl': 'https://novel.dkvirus.top/images/cover.png',
          'recentChapterUrl': _intro.recentChapterUrl,
        },
        options: Options(headers: {
          'Authorization': 'Bearer ' + token,
        })
      );

      if (result.data['code'] != '0000') {
        print(result.data['message']);
        setState(() {
          _whetherPostLoading = false;
        });
        return;
      }

      // 跳转到首页
      Navigator.pushNamedAndRemoveUntil(
          context, '/shelf', (Route<dynamic> route) => false);
    } catch (e) {
      print(e);
    }

    setState(() {
      _whetherPostLoading = false;
    });
  }
}