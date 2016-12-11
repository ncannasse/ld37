

class Merge extends h3d.shader.ScreenShader {

	static var SRC = {

		@param var tcur : Sampler2D;
		@param var tnew : Sampler2D;

		function fragment() {
			var uv = input.uv;
			output.color = min(tcur.get(uv),tnew.get(uv)) + tnew.get(uv) * 0.02;
		}

	}

}


class Composite extends h3d.shader.ScreenShader {

	static var SRC = {

		@param var bg : Sampler2D;
		@param var persist : Sampler2D;
		@const var inverse : Bool;

		function fragment() {
			var uv = input.uv;
			var c = mix( bg.get(uv) , persist.get(uv), 0.2 );
			output.color = inverse ? 1 - c : c;
		}

	}

}

@:access(h2d.Sprite)
class CustomRenderer extends h2d.RenderContext {

	public var fx : h3d.pass.ScreenFx<Composite>;
	var merge : h3d.pass.ScreenFx<Merge>;
	var blur : h3d.pass.Blur;

	public function new(s2d) {
		super(s2d);
		fx = new h3d.pass.ScreenFx(new Composite());
		merge = new h3d.pass.ScreenFx(new Merge());
		blur = new h3d.pass.Blur(1,1,0.5);
	}

	override function drawScene() {

		var bg = allocTarget("bg");
		pushTarget(bg);
		clear(Game.BG);
		super.drawScene();
		popTarget();

		var persist = allocTarget("persist");
		var blurred = allocTarget("blur");
		blur.apply(persist, allocTarget("blurTmp"), blurred);

		pushTarget(persist);
		merge.shader.tcur = blurred;
		merge.shader.tnew = bg;
		merge.render();
		popTarget();

		fx.shader.persist = persist;
		fx.shader.bg = bg;
		fx.render();
	}

}

class Game extends hxd.App {

	public static inline var BG = 0xFFF9F7F7;
	public static inline var DARK = 0x6B5757;

	public var entities = new Array<Entity>();

	public var hero : Hero;
	public var door : Door;
	public var tiles : h2d.Tile;
	public var bitmap : hxd.Pixels;
	public var collide : hxd.Pixels;
	public var event : hxd.WaitEvent;

	public var tf : h2d.Text;
	public var dieCount = 0;

	public var roomTex : h3d.mat.Texture;
	public var root : h2d.Layers;
	public var rotate : h2d.Sprite;

	public var seq : Int = 0;
	public var step : Int;

	public var custom : CustomRenderer;

	var music : hxd.snd.Channel;

	override function init() {

		s2d.setFixedSize(512, 326);


		rotate = new h2d.Sprite(s2d);
		root = new h2d.Layers(rotate);
		root.x = -s2d.width >> 1;
		root.y = -s2d.height >> 1;
		rotate.x = -root.x;
		rotate.y = -root.y;

		roomTex = hxd.Res.room.toTexture().clone();

		var carpet = new h2d.Bitmap(hxd.Res.carpet.toTile(), root);
		carpet.x = 185;
		carpet.y = 40;

		var carpet2 = new h2d.Bitmap(hxd.Res.carpet.toTile(), root);
		carpet2.x = 330;
		carpet2.y = 40;

		var room = new h2d.Bitmap(h2d.Tile.fromTexture(roomTex), root);
		tiles = hxd.Res.anims.toTile();
		bitmap = hxd.Res.anims.getPixels();

		tf = new h2d.Text(hxd.res.DefaultFont.get(), s2d);
		tf.y = 100;
		tf.visible = false;
		tf.filters = [new h2d.filter.Glow(DARK,0.8)];
		tf.letterSpacing = 3;

		custom = new CustomRenderer(s2d);
		s2d.renderer = custom;

		#if debug
		seq = 4;
		custom.fx.shader.inverse = true;
		startScenario();
		#else
		startScenario();
		#end

	}


	public function hasCollide(x:Float, y:Float) {
		var x = Std.int(x);
		var y = Std.int(y);
		return collide.getPixel(x, y)>>>24 != 0;
	}

	public function startScenario(step = -1) {
		this.step = step;

		collide = hxd.Res.room.getPixels();

		if( seq > 1 ) {
			// smaller room
			var room = collide.sub(0, 0, 245, collide.height);
			for( i in 0...150 )
				collide.blit(i, 0, room, 0, 0, room.width, room.height);
			roomTex.dispose();
		}

		roomTex.uploadPixels(collide);

		for( e in entities.copy() )
			e.remove();

		event = new hxd.WaitEvent();

		event.waitUntil(function(dt) {
			rotate.rotation = hxd.Math.angleMove(rotate.rotation, 0, 0.03 * dt);
			return rotate.rotation == 0;
		});

		hero = new Hero();
		hero.x = 222;
		hero.y = 58;

		door = new Door();
		door.x = 175;
		door.y = 276;

		if( step > 0 || seq > 1 ) {
			hero.state = Move;
			hero.y += 50;
		}

		seq--;
		nextSeq();
	}

	function nextSeq() {

		if( hero.state == Die )
			return;

		if( seq >= 0 && music == null )
			music = hxd.Res.music.play(true);

		switch( ++seq ) {
		case 0:
			hero.state = Lock;
			text("That day, I was sleeping...", function() {
				text("When suddendly...", function() {
					nextSeq();
				});
			});
		case 1:
			hero.state = Sleep;
			nextScenario();
		case 2:
			text("Was I dreaming ?!?", function() {
				text("This room.... what am I doing here?", function() {
					text("And is it trying... to KILL ME?", function() {
						nextSeq();
					});
				});
			});
		case 3:
			var txt = "And is it trying... to KILL ME?";
			//tf.text = txt;
			var all = [];
			for( i in 0...txt.length ) {
				var c = txt.charCodeAt(i);
				var t = tf.font.getChar(c);
				if( c != " ".code ) {
					var tt = t.t.clone();
					tt.dx = -(tt.width >> 1);
					tt.dy = -(tt.height >> 1);
					var c = new Shuriken(tt);
					all.push(c);
					c.anim.filters = tf.filters;
					c.x = tf.calcTextWidth(txt.substr(0,i)) + tf.x + (tt.width>>1) + t.t.dx;
					c.y = tf.y + (tt.height >> 1) + t.t.dy;
					event.wait(0.5 + Math.random() * 0.3 + i * 0.05, function() {
						shake();
						c.rotSpeed = 1e-9;
						if( haxe.Timer.stamp() - hxd.Res.shuriken.lastPlay > 0.05 ) hxd.Res.shuriken.play();
					});
				}
			}
			event.waitUntil(function(dt) {
				for( a in all )
					if( a.anim.parent == null )
						all.remove(a);
				if( all.length == 0 ) {
					event.wait(2, nextSeq);
					return true;
				}
				return false;
			});
		case 4:
			text("I must find an answer!", function() {
			});
		}
	}

	public function text( str, onEnd : Void -> Void ) {
		tf.text = str;
		tf.visible = true;
		tf.x = Std.int((s2d.width - tf.textWidth) * 0.5);
		tf.text = "";
		var t = 0.;
		var speed = 0.3;
		var prev = 0;
		var talk = [hxd.Res.talk4];
		event.waitUntil(function(dt) {
			t += dt * speed;
			var k = Std.int(t);
			if( k != prev && prev < str.length ) {
				prev = k;
				if( str.charCodeAt(k) != " ".code && str.charCodeAt(k) != ".".code )
					talk[Std.random(talk.length)].play();
				tf.text = str.substr(0, k);
			}
			var done = t > str.length + 10;
			if( hxd.Key.isPressed(hxd.Key.SPACE) ) {
				if( speed < 1 )
					speed = 1;
				else
					done = true;
			}
			if( done ) {
				tf.text = "";
				tf.visible = false;
				onEnd();
				return true;
			}
			return false;
		});
	}


	function nextScenario() {

		if( hero.state == Die )
			return;

		switch( ++step ) {
		case 0, 5, 6:

			var t = step < 5 ? 2 : 0.01;
			event.wait(t, function() {

				door.open = true;
				door.onChange = function() {

					for( i in 0...10 ) {
						event.wait(Math.random() * 0.2,function() {
							var b = new Bullet();
							b.x = door.x + 30 + Std.random(30);
							b.y = door.y + 2 + Std.random(20);
							hxd.Res.fire.play();
						});
					}

					door.onChange = nextScenario;
					event.wait(2, function() door.open = false);

				};
			});
		case 1:

			showPics(Std.int(s2d.width / 32) + Std.random(7) - 3, true);

		case 2:

			showPics( 4 + Std.random(3), false );
			event.wait(5.5, nextScenario);

		case 3:

			shake(0.1, 3);

			event.wait(0.1, function() {
				hxd.Res.wall.play();
				var dx = 0.;
				var k = 0;
				var room = hxd.Res.room.getPixels().sub(0, 0, 245, collide.height);
				event.waitUntil(function(dt) {
					dx += dt * 2;
					var change = false;
					while( dx > 1 ) {
						k++;
						if( k == 100 )
							door.y--;
						if( k > 150 ) {
							k = -1;
							event.wait(1, nextScenario);
							break;
						}
						dx--;
						collide.blit(k, 0, room, 0, 0, room.width, room.height);
						change = true;
					}
					if( change )
						roomTex.uploadPixels(collide);
					return k < 0;
				});
			});


		case 4:

			var speed = 0.03;
			var done = false;
			var chan = hxd.Res.rotate.play();
			shake(0.2, 7.5);

			event.waitUntil(function(dt) {


				var p = root.localToGlobal(new h2d.col.Point(hero.x, hero.y));
				rotate.rotation += speed * dt;
				if( rotate.rotation > Math.PI * 4 ) {
					rotate.rotation = Math.PI * 4;
					nextScenario();
					done = true;
				}

				var dx = (p.x - s2d.width * 0.5);
				var dy = (p.y - s2d.height * 0.5);

				// centrifuge
				if( hero.state == Die ) {
					if( chan != null ) {
						chan.fadeTo(0);
						chan = null;
					}
					speed *= 0.95;
				} else {
					p.x += dx * 0.01 * dt;
					p.y += dy * 0.01 * dt;

					p = root.globalToLocal(p);
					hero.x = p.x;
					hero.y = p.y;
				}

				return done;
			});

		case 7:

			event.wait(3, nextSeq);

		}
	}

	function shake(v = 1., time = 0.3) {
		var baseY = -s2d.height >> 1;
		event.waitUntil(function(dt) {
			time -= dt / 60;
			if( time < 0 ) {
				root.y = baseY;
				return true;
			}
			root.y = baseY + Math.round( hxd.Math.srand() * v * 10 * time );
			return false;
		});
	}

	function showPics( mid : Int, auto : Bool ) {
		var all = [];
		for( x in 0...Std.int(s2d.width / 16) ) {
			if( x == mid || x == mid + 1 ) continue;
			for( y in 0...Std.int(s2d.height/16) ) {
				if( !hasCollide(x * 16 + 4, y * 16 + 4) && !hasCollide(x * 16 + 12, y* 16 + 12) ) {
					var p = new Pic(x * 16 + 8, y * 16 + 8);
					event.wait( 2 - Math.abs(x - mid) * 0.1, function() {
						p.hit();
						shake();
					});
					all.push(p);
				}
			}
		}

		var endKill = false;
		event.waitUntil(function(_) {
			var xMin = 0.;
			var xMax = 1000.;

			for( p in all )
				if( p.active ? (p.anim.currentFrame > 3) : (p.anim.currentFrame < p.anim.frames.length - 3) ) {
					var x = (p.x - 8) / 16;
					if( x < mid ) {
						if( xMin < x ) xMin = x;
					} else {
						if( xMax > x ) xMax = x;
					}
				}
			if( hero.x < (xMin + 1) * 16 || hero.x > xMax * 16 ) {
				hero.die(hero.x, hero.y);
				return true;
			}

			return endKill;
		});

		event.wait(3, function() {
			for( p in all )
				event.wait( hxd.Math.abs(p.x / 16 - mid) * 0.1, p.hide.bind(function() {
					p.remove();
					all.remove(p);
					if( all.length == 0 ) {
						endKill = true;
						if( auto ) {
							if( dieCount > 3 && Std.random(3) == 0 ) step--;
							event.wait(1, nextScenario);
						}
					}
				}));
		});
	}


	override function update(dt:Float) {

		event.update(dt);
		for( e in entities.copy() )
			e.update(dt);

		s2d.ysort(2);
	}


	public static var inst : Game;

	static function main() {
		#if debug
		hxd.Res.initLocal();
		Std.instance(hxd.Res.loader.fs, hxd.fs.LocalFileSystem).createMP3 = true;
		hxd.res.Resource.LIVE_UPDATE = true;
		#else
		hxd.Res.initEmbed({compressSounds:true});
		#end
		inst = new Game();
	}

}