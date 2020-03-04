import 'dart:math';

import 'package:flutter/material.dart';
import 'package:simple_animations/simple_animations.dart';



class ParticleBackgroundApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(children: <Widget>[
      Positioned.fill(child: AnimatedBackground()),
      Positioned.fill(child: Particles(20)),
//      Positioned.fill(child: CenteredText()),
    ]);
  }
}


class Particles extends StatefulWidget {
  final int numberOfParticles;

  Particles(this.numberOfParticles);

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
      if(circleTap(particle.position.dx, particle.position.dy, tapPosition.dx, tapPosition.dy, particle.calculatedSize)>=0){
        particle.state=ParticleState.CURED
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
    final duration = Duration(milliseconds:7000 + random.nextInt(6000));

    tween = MultiTrackTween([
      Track("x").add(
          duration, Tween(begin: startPosition.dx, end: endPosition.dx),
          curve: Curves.easeInOutSine),
      Track("y").add(
          duration, Tween(begin: startPosition.dy, end: endPosition.dy),
          curve: Curves.easeIn),
    ]);
    animationProgress = AnimationProgress(duration: duration, startTime: time);
    size = 0.2 + random.nextDouble() * 0.4;
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

  ParticlePainter(this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    final viruspaint = Paint()..color = Colors.red;

    particles.forEach((particle) {
      var progress = particle.animationProgress.progress(time);
      final animation = particle.tween.transform(progress);
      final position =
          Offset(animation["x"] * size.width, animation["y"] * size.height);
      particle.position=position;
      particle.calculatedSize=size.width*0.2*particle.size;

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
        canvas.drawCircle(position, particle.calculatedSize,
            particle.isVirus() ? viruspaint : paint);
      }
    });
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
}

class AnimatedBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tween = MultiTrackTween([
      Track("color1").add(Duration(seconds: 10),
          ColorTween(begin: Colors.grey.shade700, end: Colors.black)),
      Track("color2").add(Duration(seconds: 10),
          ColorTween(begin: Colors.black, end: Colors.grey.shade700))
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

class CenteredText extends StatelessWidget {
  const CenteredText({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text(
      "Welcome",
      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w200),
      textScaleFactor: 4,
    ));
  }
}

enum ParticleState {
  NORMAL,
  VIRUS,
  CURED
}

