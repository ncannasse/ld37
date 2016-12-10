

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
	public var bitmap : hxd.Pixels.PixelsARGB;
	public var collide : hxd.Pixels.PixelsARGB;
	public var event : hxd.WaitEvent;

	public var tf : h2d.Text;
	public var dieCount = 0;

	var step : Int;

	override function init() {
		s2d.setFixedSize(512, 326);

		new h2d.Bitmap(hxd.Res.room.toTile(), s2d);
		tiles = hxd.Res.anims.toTile();
		bitmap = hxd.Res.anims.getPixels();
		collide = hxd.Res.room.getPixels();

		var c = new CustomRenderer(s2d);
		s2d.renderer = c;

		startScenario();
	}


	public function hasCollide(x:Float, y:Float) {
		var x = Std.int(x);
		var y = Std.int(y);
		return collide.getPixel(x, y) != 0xFFF9F7F7;
	}

	public function text(t) {
	}


	public function startScenario() {

		for( e in entities.copy() )
			e.remove();

		event = new hxd.WaitEvent();

		hero = new Hero();
		hero.x = 222;
		hero.y = 58;

		door = new Door();
		door.x = 175;
		door.y = 276;

		step = 0;
		nextScenario();
	}

	function nextScenario() {

		if( hero.state == Die )
			return;

		switch( step++ ) {
		case 0:
			hxd.Res.tonals.play();
			event.wait(2, function() {

				text("Evade!");

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

					event.wait(3, nextScenario);

				};
			});
		case 1:

			hxd.Res.vibrate.play();
			var mid = Std.int(s2d.width / 32) + Std.random(7) - 3;
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
			event.wait(3, function() {
				for( p in all )
					event.wait( hxd.Math.abs(p.x / 16 - mid) * 0.1, p.hide.bind(function() {
						p.remove();
						all.remove(p);
						if( all.length == 0 ) {
							if( dieCount > 3 && Std.random(3) == 0 ) step--;
							event.wait(1, nextScenario);
						}
					}));
			});



		}
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