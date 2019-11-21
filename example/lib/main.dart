import 'dart:async';

import 'package:flutter/material.dart';
import 'package:painter/painter.dart';
import 'dart:typed_data';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Painter Example',
      home: new ExamplePage(),
    );
  }
}

class ExamplePage extends StatefulWidget {
  @override
  _ExamplePageState createState() => new _ExamplePageState();
}

class _ExamplePageState extends State<ExamplePage> {

  bool _finished;
  PainterController _controller;

  @override
  void initState() {
    super.initState();
    _finished=false;
    _controller=_newController();
  }

  PainterController _newController(){
    PainterController controller=new PainterController();
    controller.thickness=5.0;
    controller.backgroundColor=Colors.green;

    Future.delayed(Duration.zero, () async {
      String path = 'https://i.postimg.cc/ydwkDFGz/unnamed.jpg';
      NetworkImage img = new NetworkImage(path);
      img.resolve(ImageConfiguration()).addListener(
        ImageStreamListener((ImageInfo info, bool _) {
          controller.backgroundImage = info.image;
        }),
      );
    });

    return controller;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> actions;
    if(_finished){
      actions = <Widget>[
        new IconButton(
          icon: new Icon(Icons.content_copy),
          tooltip: 'New Painting',
          onPressed: ()=>setState((){
            _finished=false;
            _controller=_newController();
          }),
        ),
      ];
    } else {
      actions = <Widget>[
        new IconButton(
            icon: new Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed:  _controller.undo
        ),
        new IconButton(
            icon: new Icon(Icons.delete),
            tooltip: 'Clear',
            onPressed:  _controller.clear
        ),
        new IconButton(
            icon: new Icon(Icons.check),
            onPressed: ()=>_show( _controller.finish(),context)
        ),
      ];
    }
    return new Scaffold(
      appBar: new AppBar(
          title: const Text('Painter Example'),
          actions:actions,
          bottom: new PreferredSize(
            child: new DrawBar(_controller),
            preferredSize: new Size(MediaQuery.of(context).size.width,30.0),
          )
      ),
      body: new Center(
          child:new AspectRatio(
              aspectRatio: 1.0,
              child: new Painter( _controller)
          )
      ),
    );
  }

  void _show(PictureDetails picture,BuildContext context){
    setState(() {
      _finished=true;
    });
    Navigator.of(context).push(
        new MaterialPageRoute(builder: (BuildContext context){
          return new Scaffold(
            appBar: new AppBar(
              title: const Text('View your image'),
            ),
            body: new Container(
                alignment: Alignment.center,
                child:new FutureBuilder<Uint8List>(
                  future:picture.toPNG(),
                  builder: (BuildContext context, AsyncSnapshot<Uint8List> snapshot){
                    switch (snapshot.connectionState)
                    {
                      case ConnectionState.done:
                        if (snapshot.hasError){
                          return new Text('Error: ${snapshot.error}');
                        }else{
                          return Image.memory(snapshot.data);
                        }
                        break;
                      default:
                        return new Container(
                            child:new FractionallySizedBox(
                              widthFactor: 0.1,
                              child: new AspectRatio(
                                  aspectRatio: 1.0,
                                  child: new CircularProgressIndicator()
                              ),
                              alignment: Alignment.center,
                            )
                        );
                    }
                  },
                )
            ),
          );
        })
    );
  }
}

class DrawBar extends StatelessWidget {

  final PainterController _controller;

  DrawBar(this._controller);

  @override
  Widget build(BuildContext context) {
    return  new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        new Flexible(
            child: new StatefulBuilder(
                builder: (BuildContext context,StateSetter setState){
                  return new Container(
                      child: new Slider(
                        value:  _controller.thickness,
                        onChanged: (double value)=>setState((){
                          _controller.thickness=value;
                        }),
                        min: 1.0,
                        max: 20.0,
                        activeColor: Colors.white,
                      )
                  );
                }
            )
        ),
        new ColorPickerButton( _controller, false),
        new ColorPickerButton( _controller, true),
      ],
    );
  }
}


class ColorPickerButton extends StatefulWidget {

  final PainterController _controller;
  final bool _background;

  ColorPickerButton(this._controller,this._background);

  @override
  _ColorPickerButtonState createState() => new _ColorPickerButtonState();
}

class _ColorPickerButtonState extends State<ColorPickerButton> {
  @override
  Widget build(BuildContext context) {
    return new IconButton(
        icon: new Icon(_iconData,color: _color),
        tooltip: widget._background?'Change background color':'Change draw color',
        onPressed: _pickColor
    );
  }

  void _pickColor(){
    Color pickerColor=_color;
    Navigator.of(context).push(
        new MaterialPageRoute(
            fullscreenDialog: true,
            builder: (BuildContext context){
              return new Scaffold(
                  appBar: new AppBar(
                    title: const Text('Pick color'),
                  ),
                  body: new Container(
                      alignment: Alignment.center,
                      child: new ColorPicker(
                        pickerColor: pickerColor,
                        onColorChanged: (Color c)=>pickerColor=c,
                      )
                  )
              );
            }
        )
    ).then((_){
      setState((){
        _color=pickerColor;
      });
    });
  }

  Color get _color=>widget._background?widget._controller.backgroundColor:widget._controller.drawColor;

  IconData get _iconData=>widget._background?Icons.format_color_fill:Icons.brush;

  set _color(Color color){
    if(widget._background){
      widget._controller.backgroundColor=color;
    } else {
      widget._controller.drawColor=color;
    }
  }
}


