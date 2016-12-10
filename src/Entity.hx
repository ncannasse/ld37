class Entity {

	var game : Game;
	public var anim : h2d.Anim;

	public var x(get, set) : Float;
	public var y(get,set) : Float;

	public function new() {
		game = Game.inst;
		anim = new h2d.Anim();
		game.root.add(anim, 2);
		game.entities.push(this);
	}

	public function play(a, ?s = 12., ?onEnd) {
		if( a == null ) a = [h2d.Tile.fromColor(0, 0, 0)];
		anim.play(a);
		anim.speed = s;
		anim.onAnimEnd = onEnd == null ? function() {} : onEnd;
	}

	public function remove() {
		anim.remove();
		game.entities.remove(this);
	}

	function get_x() return anim.x;
	function set_x(v) { anim.x = v; return v; }
	function get_y() return anim.y;
	function set_y(v) { anim.y = v; return v; }

	function checkHitHero(dx,dy) {
		var f = game.hero.anim.getFrame();

		var hx = game.hero.x + f.dx;
		var hy = game.hero.y + f.dy;

		var ix = Std.int(x - hx);
		var iy = Std.int(y - hy);

		if( game.hero.anim.scaleX < 0 )
			ix = f.width - ix;


		if( ix < 0 || ix >= f.width )
			return false;
		if( iy < 0 || iy >= f.height )
			return false;
		if( (game.bitmap.getPixel(f.x + ix, f.y + iy) >>> 24) == 0 )
			return false;

		game.hero.die(hx + ix, hy + iy, dx, dy);

		return true;
	}

	public function update(dt:Float) {
	}

}