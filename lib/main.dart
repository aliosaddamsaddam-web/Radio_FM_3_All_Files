import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:just_audio/just_audio.dart';

void main() => runApp(const RadioApp());

class RadioApp extends StatelessWidget {
  const RadioApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Radio FM 3',
    theme: ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0B1020),
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark),
    ),
    home: const RadioHome(),
  );
}

class Station {
  final String name, url, country;
  const Station(this.name, this.url, this.country);
  factory Station.fromJson(Map<String,dynamic> j) =>
    Station('${j['name'] ?? 'Radio'}', '${j['url_resolved'] ?? j['url'] ?? ''}', '${j['country'] ?? ''}');
}

class RadioHome extends StatefulWidget {
  const RadioHome({super.key});
  @override
  State<RadioHome> createState() => _RadioHomeState();
}

class _RadioHomeState extends State<RadioHome> {
  final player = AudioPlayer();
  final search = TextEditingController();
  final stations = <Station>[];
  Station? current;
  bool internet = false, loading = false;
  String? error;
  double frequency = 98.5;

  Future<void> findStations(String q) async {
    setState(() { loading = true; error = null; });
    try {
      final uri = Uri.https('de1.api.radio-browser.info','/json/stations/search',{
        'name': q.trim().isEmpty ? 'Yemen' : q.trim(),
        'limit':'40','hidebroken':'true','order':'votes','reverse':'true'
      });
      final r = await http.get(uri).timeout(const Duration(seconds:20));
      if (r.statusCode != 200) throw Exception();
      final data = jsonDecode(r.body) as List;
      final found = data.whereType<Map<String,dynamic>>().map(Station.fromJson)
        .where((s)=>s.url.startsWith('http')).toList();
      if (!mounted) return;
      setState(() { stations..clear()..addAll(found); if(found.isEmpty) error='لم يتم العثور على محطات.'; });
    } catch (_) {
      if (mounted) setState(()=>error='تعذر الاتصال. تحقق من الإنترنت.');
    } finally { if(mounted) setState(()=>loading=false); }
  }

  Future<void> play(Station s) async {
    setState(()=>current=s);
    try { await player.setUrl(s.url); await player.play(); }
    catch (_) { if(mounted) setState(()=>error='تعذر تشغيل هذه المحطة.'); }
  }

  void fmInfo() => showDialog<void>(context:context,builder:(c)=>AlertDialog(
    title: const Text('راديو FM الحقيقي'),
    content: const Text('هذه الشاشة تعرض التردد فقط. استقبال FM بلا إنترنت يحتاج شريحة FM مدعومة وواجهة نظام من الشركة المصنّعة. السماعة قد تعمل كهوائي في الأجهزة المدعومة، لكنها لا تضيف مستقبل FM للهاتف.'),
    actions:[TextButton(onPressed:()=>Navigator.pop(c),child:const Text('حسناً'))],
  ));

  @override
  void initState(){super.initState(); findStations('Yemen');}
  @override
  void dispose(){player.dispose();search.dispose();super.dispose();}

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title:const Text('RADIO FM 3'),centerTitle:true,backgroundColor:const Color(0xFF111A2E)),
    body: SafeArea(child:Column(children:[
      const SizedBox(height:12),
      const Icon(Icons.radio,size:62,color:Colors.lightBlueAccent),
      const Text('راديو اليمن والعالم',style:TextStyle(fontSize:22,fontWeight:FontWeight.bold)),
      Padding(padding:const EdgeInsets.all(14),child:SegmentedButton<bool>(
        segments:const [
          ButtonSegment(value:false,label:Text('FM بدون إنترنت'),icon:Icon(Icons.waves)),
          ButtonSegment(value:true,label:Text('راديو الإنترنت'),icon:Icon(Icons.wifi)),
        ],
        selected:{internet},onSelectionChanged:(s)=>setState(()=>internet=s.first),
      )),
      if(!internet)...[
        const Text('التردد المختار'),
        Text('${frequency.toStringAsFixed(1)} MHz',style:const TextStyle(fontSize:42,color:Colors.lightBlueAccent,fontWeight:FontWeight.bold)),
        Slider(min:87.5,max:108,value:frequency,onChanged:(v)=>setState(()=>frequency=v)),
        Row(mainAxisAlignment:MainAxisAlignment.center,children:[
          IconButton(onPressed:()=>setState(()=>frequency=(frequency-.1).clamp(87.5,108)),icon:const Icon(Icons.remove_circle_outline),iconSize:32),
          IconButton(onPressed:fmInfo,icon:const Icon(Icons.play_circle_fill,color:Colors.lightBlueAccent),iconSize:42),
          IconButton(onPressed:()=>setState(()=>frequency=(frequency+.1).clamp(87.5,108)),icon:const Icon(Icons.add_circle_outline),iconSize:32),
        ]),
        const Padding(padding:EdgeInsets.all(16),child:Text('التردد تجريبي؛ تشغيل FM الحقيقي غير مفعّل في هذه النسخة.',textAlign:TextAlign.center,style:TextStyle(color:Colors.white60))),
      ] else ...[
        Padding(padding:const EdgeInsets.all(12),child:Row(children:[
          Expanded(child:TextField(controller:search,onSubmitted:findStations,decoration:const InputDecoration(hintText:'ابحث عن محطة أو بلد',border:OutlineInputBorder(),isDense:true))),
          IconButton.filled(onPressed:()=>findStations(search.text),icon:const Icon(Icons.search)),
        ])),
        if(current!=null) Text('المحطة الحالية: ${current!.name}',maxLines:1,overflow:TextOverflow.ellipsis),
        StreamBuilder<PlayerState>(stream:player.playerStateStream,builder:(c,s){
          final playing=s.data?.playing??false;
          return FilledButton.icon(onPressed:() async {
            if(playing){await player.pause();}
            else if(current!=null){await player.play();}
            else if(stations.isNotEmpty){await play(stations.first);}
            if(mounted)setState((){});
          },icon:Icon(playing?Icons.pause:Icons.play_arrow),label:Text(playing?'إيقاف مؤقت':'تشغيل'));
        }),
        if(loading)const Padding(padding:EdgeInsets.all(8),child:CircularProgressIndicator()),
        if(error!=null)Padding(padding:const EdgeInsets.all(8),child:Text(error!,textAlign:TextAlign.center,style:const TextStyle(color:Colors.orangeAccent))),
        Expanded(child:stations.isEmpty?const Center(child:Text('ابحث عن محطة إذاعية')):ListView.builder(
          itemCount:stations.length,itemBuilder:(c,i){final s=stations[i];return ListTile(
            leading:const CircleAvatar(child:Icon(Icons.radio)),title:Text(s.name,maxLines:1,overflow:TextOverflow.ellipsis),
            subtitle:Text(s.country),trailing:const Icon(Icons.play_arrow),onTap:()=>play(s));},
        )),
      ],
      const Padding(padding:EdgeInsets.all(10),child:Text('السماعة السلكية قد تعمل كهوائي للأجهزة المدعومة',style:TextStyle(fontSize:11,color:Colors.white60))),
    ])),
  );
}