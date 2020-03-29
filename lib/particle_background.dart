import 'dart:async';
import 'dart:math';
import 'dart:developer' as dev;



import 'package:firebase/firebase.dart';
import 'package:flutter/material.dart';
import 'package:marquee/marquee.dart';
import 'package:simple_animations/simple_animations.dart';

enum VirusState{
  GLOBAL,
  LOCAL
}
class VirusEvent{
  VirusState state;
  var value;
  VirusEvent(this.state,this.value);
}

class ParticleBackgroundApp extends StatelessWidget {

  ChangeNotifier notifier= ChangeNotifier();
  StreamController<VirusEvent> _controller = StreamController<VirusEvent>();




  @override
  Widget build(BuildContext context) {
    Size size=MediaQuery.of(context).size;
    fetchData();
//    return Text(
//      "Killed: ",
//      style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900,decoration: TextDecoration.none),
//      textScaleFactor: 3,
//    );
    return Stack(children: <Widget>[
      Positioned.fill(child: AnimatedBackground()),
      Positioned.fill(child: CenteredText(_controller.stream),left:10,top: 10),
      Positioned.fill(child: BottomText(),top: size.height-30),
      Positioned.fill(child: Particles(30,_controller)),

    ]);
  }

  void fetchData () {
    print("fetching data");
    Database db = database();
    DatabaseReference ref = db.ref('messages');
    if(ref!=null) {
      print("ref");
      ref.onValue.listen((e) {
        DataSnapshot datasnapshot = e.snapshot;
        try {
          var value = datasnapshot.child("count").val();
          print("value: " + value.toString());
          _controller.add(VirusEvent(VirusState.GLOBAL, value));
        }catch(e){
          print(e);
        }
        // Do something with datasnapshot
      });
    }else{
//      stdout.writeln("Null reference");
      dev.log("Null reference");
      print("Null Reference");
    }
  }
}


class Particles extends StatefulWidget {
  final int numberOfParticles;

  StreamController<VirusEvent> controller;


  Particles(this.numberOfParticles, this.controller);

  @override
  _ParticlesState createState() => _ParticlesState();
}

class _ParticlesState extends State<Particles> {
  final Random random = Random();

  final List<ParticleModel> particles = [];

  @override
  void initState() {
    List.generate(widget.numberOfParticles, (index) {
      particles.add(ParticleModel(random,index==0?ParticleState.VIRUS:ParticleState.NORMAL));
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Rendering(
      startTime: Duration(seconds: 20),
      onTick: _simulateParticles,
      builder: (context, time) {
        return
            GestureDetector(onTapDown:(TapDownDetails details)  => _hitParticle(details.globalPosition), child: CustomPaint(
              painter: ParticlePainter(particles, time),
            ));

      },
    );
  }

  _simulateParticles(Duration time) {
    int index=0;
    particles.forEach((particle) => particle.maintainRestart(time,index++==0));
  }

  _hitParticle(Offset tapPosition) {
    particles.forEach((particle)=>{
      if(particle.isVirus() && circleTap(particle.position.dx, particle.position.dy, tapPosition.dx, tapPosition.dy, particle.calculatedSize)>=0){
        particle.state=ParticleState.CURED,
        widget.controller.add(VirusEvent(VirusState.LOCAL, 1))
      }

    });
  }

  int circleTap(double x1, double y1, double x2,
      double y2, double r1)
  {
    double distSq = (x1 - x2) * (x1 - x2) +
        (y1 - y2) * (y1 - y2);
    double radSumSq = r1* r1;
    if (distSq == radSumSq)
      return 1;
    else if (distSq > radSumSq)
      return -1;
    else
      return 0;
  }
}


class ParticleModel {
  Animatable tween;
  double size;
  AnimationProgress animationProgress;
  Random random;
  Offset position;
  double calculatedSize;
  ParticleState state;



  isVirus(){
    return this.state==ParticleState.VIRUS;
  }

  isNormal(){
    return this.state==ParticleState.NORMAL;
  }

  isCured(){
    return this.state==ParticleState.CURED;
  }

  ParticleModel(this.random,this.state) {
    restart();
  }

  restart({Duration time = Duration.zero}) {
    final startPosition = Offset(-0.2 + 1.4 * random.nextDouble(), 1.2);
    final endPosition = Offset(-0.2 + 1.4 * random.nextDouble(), -0.2);
    final duration = Duration(milliseconds:12000 + random.nextInt(6000));

    tween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: Curves.easeInOutSine),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: Curves.easeIn),
    ]);
    animationProgress = AnimationProgress(duration: duration, startTime: time);
    size = 0.2 + random.nextDouble() * 0.1;
  }

  maintainRestart(Duration time,bool virus) {
    if (animationProgress.progress(time) == 1.0) {
      this.state=virus?ParticleState.VIRUS:ParticleState.NORMAL;
      restart(time: time);
    }
  }
}

class ParticlePainter extends CustomPainter {
  List<ParticleModel> particles;
  Duration time;
  Image virusImage;


  ParticlePainter(this.particles, this.time){
    virusImage=Image.asset("virus.png");
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.7);
    final viruspaint = Paint()..color = Colors.red.withOpacity(0.7);

    particles.forEach((particle) {
      var progress = particle.animationProgress.progress(time);
      final animation = particle.tween.transform(progress);
      final position =
          Offset(animation["x"] * size.width, animation["y"] * size.height);
      particle.position=position;
      particle.calculatedSize=(size.width>size.height?size.width:size.height)*0.14*particle.size;

      if(particle.isVirus()){
        particles.forEach((mParticle){
            if(mParticle.isNormal() && mParticle.position!=null){
              if(checkCollision(particle,mParticle)>=0){
                  mParticle.state=ParticleState.VIRUS;
              }
            }
        });
      }
      if(!particle.isCured()) {
//        if(particle.isVirus()){
//          canvas.drawImage(virusImage, position, paint);
//        }
        canvas.drawCircle(position, particle.calculatedSize,
            particle.isVirus() ? viruspaint : paint);

      }
    });
//    drawText(canvas,size);
  }

  int checkCollision(ParticleModel particle1, ParticleModel particle2){
    return circleCollision(particle1.position.dx,particle1.position.dy,particle2.position.dx,particle2.position.dy,particle1.calculatedSize,particle2.calculatedSize);
  }

  int circleCollision(double x1, double y1, double x2,
      double y2, double r1, double r2)
  {
    double distSq = (x1 - x2) * (x1 - x2) +
        (y1 - y2) * (y1 - y2);
    double radSumSq = (r1 + r2) * (r1 + r2);
    if (distSq == radSumSq)
      return 1;
    else if (distSq > radSumSq)
      return -1;
    else
      return 0;
  }



  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;

  void drawText(Canvas canvas, Size size) {
    TextSpan span = new TextSpan(style: new TextStyle(color: Colors.white), text: "Fact:  Help textssss");
    TextPainter tp = new TextPainter(text: span, textAlign: TextAlign.center, textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, new Offset(5.0, size.height-20));

  }
}

class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tween = MultiTrackTween([
      Track("color1").add(Duration(seconds: 4),
          ColorTween(begin: Colors.grey.shade900, end: Colors.brown.shade800)),
      Track("color2").add(Duration(seconds: 4),
          ColorTween(begin: Colors.brown.shade700, end: Colors.red.shade600))
    ]);

    return ControlledAnimation(
      playback: Playback.MIRROR,
      tween: tween,
      duration: tween.duration,
      builder: (context, animation) {
        return Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [animation["color1"], animation["color2"]])),
        );
      },
    );
  }
}

class BottomText extends StatelessWidget{
  @override
  Widget build(BuildContext context) {

    return Center(child:Marquee(startPadding: 10,
      blankSpace: 10,
      text:"Stay positive.  You never gonna lose this Game, so is our humanity in its fight against coronavirus.  Stay Home, #socialdistancing is the best way to prevent.  84% of the affected have already recovered/discharged.   Steps to prevent are so simple, keep washing your hands and DONOT touch your face after you touch any foreign object.  Humanity has seen worse until last century, and we have always come back.  Stay Strong and think of it as an opportunity to give a break to mother nature.   Pray for the victims and their families to be strong.  Together we will survive.",
      style: TextStyle(fontSize: 10,color: Colors.white, fontWeight: FontWeight.w900,decoration: TextDecoration.none),

    ));
  }

}


class CenteredText extends StatefulWidget  {
  final Stream<VirusEvent> stream;
  int globalScore=0;
  int  score=0;
  int oldScore=0;



   CenteredText(this.stream, {
    Key key,
  }) : super(key: key){
     startTimer();
   }



  @override
  State<StatefulWidget> createState() {
    return _ScoreText();
  }

  void startTimer() {
    Database db = database();
    DatabaseReference ref = db.ref('messages');
     Timer.periodic(Duration(seconds:10), (timer) {
       if(score!=oldScore && globalScore>1000) {
         var updates = {};
         updates['count'] = globalScore + (score-oldScore);
         ref.update(updates);
         oldScore=score;
       }
     });
  }
}

class _ScoreText extends State<CenteredText>{


@override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.stream.listen((event) { setState(() {
      if(event.state==VirusState.GLOBAL){
        if(event.value>widget.globalScore) {
          widget.globalScore = event.value;
        }
      }else if(event.state==VirusState.LOCAL)
        widget.score=widget.score+event.value;
    });});
  }

  @override
  Widget build(BuildContext context) {
  
    return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
        children:[
      Text(
        "Global: "+widget.globalScore.toString(),
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,decoration: TextDecoration.none),
        textScaleFactor: 0.3,
      ),
      Text(
      "Killed: "+widget.score.toString(),
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900,decoration: TextDecoration.none),
      textScaleFactor: 0.25,
    )
    ]
    );
  }


}

enum ParticleState {
  NORMAL,
  VIRUS,
  CURED
}

