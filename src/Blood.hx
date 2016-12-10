private class BE extends h2d.SpriteBatch.BatchElement {
	public var frame : Float = 0.;
	var frames : Array<h2d.Tile>;

	public function new(frames) {
		this.frames = frames;
		super(frames[0]);
	}

	override function update(et:Float) {
		var dt = et * 60;
		frame += dt * 0.5 / (frame + 2);
		var i = Std.int(frame);
		if( i >= frames.length ) i = frames.length - 1;
		t = frames[i];
		return true;
	}
}

private class PE extends BE {

	public var vx : Float;
	public var z : Float = 0.;
	public var vz : Float = 0.;

	override function update(et:Float) {
		var dt = et * 60;
		x += vx * dt;
		var dz = vz * dt;
		z += dz;
		y += dz;
		if( z > 0 ) {
			y -= z;
			z = 0;
			vx *= Math.pow(0.5, dt);

			super.update(et);
		}
		vz += 0.2 * dt;
		vx *= Math.pow(0.9, dt);
		return true;
	}

}

class Blood extends Entity {

	var b : h2d.SpriteBatch;

	public function new(x, y, vx, vy) {
		super();
		play(null);

		b = new h2d.SpriteBatch(game.tiles);
		game.s2d.add(b, 1);
		b.hasUpdate = true;
		b.blendMode = Multiply;
		var frames = [for( dy in 0...2 ) [for( t in game.tiles.sub(0, 64+dy*16, 112, 16).split() ) { t.dx = -8; t.dy = -8; t; }]];
		for( i in 0...10 ) {
			var e = new BE(frames[Std.random(frames.length)]);
			e.x = hxd.Math.srand(5);
			e.y = hxd.Math.srand(5);
			b.add(e);
		}

		var parts = new h2d.SpriteBatch(game.tiles, anim);
		parts.hasUpdate = true;
		parts.blendMode = Multiply;
		for( i in 0...10 ) {
			var e = new PE(frames[Std.random(frames.length)]);
			e.x = hxd.Math.srand(5);
			e.y = hxd.Math.srand(5);
			e.vx = hxd.Math.srand(3);
			e.vz = -(0.5 + hxd.Math.random(1)) * 3;
			parts.add(e);
		}
		game.s2d.add(anim, 3); // over

		this.x = b.x = x;
		this.y = b.y = y;
	}

	override public function remove() {
		super.remove();
		b.remove();
	}

}