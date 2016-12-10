

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

		function fragment() {
			var uv = input.uv;
			output.color = mix( bg.get(uv) , persist.get(uv), 0.2 );
		}

	}

}

@:access(h2d.Sprite)
class CustomRenderer extends h2d.RenderContext {

	var fx : h3d.pass.ScreenFx<Composite>;
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
		clear(0xFFFFFF);
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

	var step : Int;
	var rotate : h2d.Sprite;

	override function init() {
		s2d.setFixedSize(512, 326);


		rotate = new h2d.Sprite(s2d);
		root = new h2d.Layers(rotate);
		root.x = -s2d.width >> 1;
		root.y = -s2d.height >> 1;
		rotate.x = -root.x;
		rotate.y = -root.y;

		roomTex = hxd.Res.room.toTexture().clone();
		var room = new h2d.Bitmap(h2d.Tile.fromTexture(roomTex), root);
		tiles = hxd.Res.anims.toTile();
		bitmap = hxd.Res.anims.getPixels();

		var c = new CustomRenderer(s2d);
		s2d.renderer = c;

		startScenario(3);
	}


	public function hasCollide(x:Float, y:Float) {
		var x = Std.int(x);
		var y = Std.int(y);
		return collide.getPixel(x, y) != 0xFFF9F7F7;
	}

	public function startScenario(step = 0) {
		this.step = step;

		collide = hxd.Res.room.getPixels();
		roomTex.uploadPixels(collide);

		for( e in entities.copy() )
			e.remove();

		event = new hxd.WaitEvent();

		event.waitUntil(function(dt) {
			rotate.rotation = hxd.Math.angleMove(rotate.rotation, 0, 0.03 * dt);
			hero.anim.rotation = -rotate.rotation;
			return rotate.rotation == 0;
		});

		hero = new Hero();
		hero.x = 222;
		hero.y = 58;

		door = new Door();
		door.x = 175;
		door.y = 276;

		if( step > 0 ) {
			hero.state = Move;
			hero.y += 50;
		}

		nextScenario();
	}

	function nextScenario() {

		if( hero.state == Die )
			return;

		switch( step++ ) {
		case 0:
			hxd.Res.tonals.play();
			event.wait(2, function() {

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
			event.wait(5, nextScenario);

		case 3:

			hxd.Res.cygal.play();

			event.wait(0.1, function() {
				var dx = 0.;
				var k = 0;
				var room = hxd.Res.room.getPixels().sub(0, 0, 250, collide.height);
				event.waitUntil(function(dt) {
					dx += dt * 2;
					var change = false;
					while( dx > 1 ) {
						k++;
						if( k > 150 ) {
							k = -1;
							nextScenario();
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
			event.waitUntil(function(dt) {


				var p = root.localToGlobal(new h2d.col.Point(hero.x, hero.y));
				rotate.rotation += speed * dt;

				var dx = (p.x - s2d.width * 0.5);
				var dy = (p.y - s2d.height * 0.5);

				// centrifuge
				if( hero.state == Die )
					speed *= 0.95;
				else {
					p.x += dx * 0.01 * dt;
					p.y += dy * 0.01 * dt;

					p = root.globalToLocal(p);
					hero.x = p.x;
					hero.y = p.y;
				}
				hero.anim.rotation = -rotate.rotation;

				return false;
			});


		}
	}

	function showPics( mid : Int, auto : Bool ) {
		var all = [];
		for( x in 0...Std.int(s2d.width / 16) ) {
			if( x == mid ) continue;
			for( y in 0...Std.int(s2d.height/16) ) {
				if( !hasCollide(x * 16 + 4, y * 16 + 4) && !hasCollide(x * 16 + 12, y* 16 + 12) ) {
					var p = new Pic(x * 16 + 8, y * 16 + 8);
					event.wait( 2 - Math.abs(x - mid) * 0.1, p.hit);
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
		hxd.Res.initLocal();
		hxd.res.Resource.LIVE_UPDATE = true;
		//Data.load(hxd.Res.data.entry.getText());
		inst = new Game();
	}

}