import hxd.Key in K;

enum State {
	Sleep;
	Move;
	Lock;
	Die;
}

typedef Anim = Array<h2d.Tile>;

class Hero extends Entity {

	public var state(default,set) : State;

	var anims : {
		sleep : Anim,
		wake : Anim,
		sleepDead : Anim,
		walk : Anim,
		walkUp : Anim,
		walkDown : Anim,
		deadStand : Anim,
	};

	public function new() {
		super();
		var sleep = game.tiles.sub(0, 32, 32 * 3, 32).split();
		for( t in sleep ) {
			t.dx = -16;
			t.dy = -32;
		}
		var n = 10;
		var walk = [for( t in game.tiles.sub(0, 0, 16 * n, 32).split(n) ) { t.dx = -8; t.dy = -32; t; }];

		var wake = [for( t in game.tiles.sub(96, 32, 128 + 32, 32).split() ) { t.dx = -16; t.dy = -24; t; }];

		var dstand = [for( t in game.tiles.sub(0,144, 128, 32).split() ) { t.dx = -8; t.dy = -32; t; }];

		anims = {
			sleep : sleep,
			wake : wake,
			sleepDead : [game.tiles.sub(112, 64, 32, 16, -16, -16)],
			walk : [for( i in [6, 7, 8, 9, 6] ) walk[i]],
			walkDown : [for( i in [0, 1, 0, 2] ) walk[i]],
			walkUp : [for( i in [3, 4, 3, 5] ) walk[i]],
			deadStand : dstand,
		};
		state = Sleep;
	}

	function set_state(s) : State {
		if( state == s )
			return s;
		switch(s)  {
		case Sleep:
			play(anims.sleep, 4);
		case Move:
			play(anims.walkDown, 20);
		case Die:
			switch( state ) {
			case Move, Lock:
				play(anims.deadStand);
				anim.loop = false;
			case Sleep:
				play(anims.sleepDead);
			default:
			}
		case Lock:
		}
		return state = s;
	}

	public function die(x, y, dx = 0., dy = -1.) {
		if( state == Die ) return;
		hxd.Res.die.play();
		new Blood(x,y, dx, dy);
		state = Die;
	}

	override public function update(dt:Float) {


		anim.rotation = -game.rotate.rotation;


		switch( state ) {
		case Sleep:

			if( K.isPressed(K.DOWN) ) {
				state = Lock;
				play(anims.wake, 20,function() { y += 12; state = Move; });
			}

		case Move:
			var dx = 0, dy = 0;
			if( K.isDown(K.LEFT) )
				dx--;
			if( K.isDown(K.RIGHT) )
				dx++;
			if( K.isDown(K.UP) )
				dy--;
			if( K.isDown(K.DOWN) )
				dy++;

			if( dx != 0 ) {
				anim.scaleX = dx * anim.scaleY;
				anim.frames = anims.walk;
			} else if( dy != 0 )
				anim.frames = dy > 0 ? anims.walkDown : anims.walkUp;

			if( dx == 0 && dy == 0 )
				anim.currentFrame = 0.4;

			var cs = Math.cos(anim.rotation);
			var ss = Math.sin(anim.rotation);

			var mx = dx * cs - dy * ss;
			var my = dx * ss + dy * cs;

			var ms = dt * 1.5;
			mx *= ms;
			my *= ms;


			for( i in 0...4 ) {
				var mx = mx * 0.25;
				var my = my * 0.25;
				if( !game.hasCollide(x+mx, y-4) && !game.hasCollide(x+mx, y-2) && !game.hasCollide(x+mx, y) )
					x += mx;
				if( !game.hasCollide(x-2, y+my - (dy<0?4:0)) && !game.hasCollide(x, y+my - (dy<0?4:0)) && !game.hasCollide(x+2, y+my - (dy<0?4:0)) )
					y += my;
			}
			if( game.hasCollide(x, y) || K.isPressed(K.ESCAPE) )
				die(x, y);
		case Lock:
		case Die:
			if( K.isPressed(K.SPACE) || K.isPressed(K.ESCAPE) ) {
				state = Lock;
				game.dieCount++;
				haxe.Timer.delay(function() game.startScenario(), 0);
			}
		}

	}

}