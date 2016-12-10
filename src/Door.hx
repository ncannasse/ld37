class Door extends Entity {

	var ldoor : h2d.Sprite;
	var rdoor : h2d.Sprite;
	var opening : Float = 0.;
	public var open(default,set) : Bool = false;

	public function new() {
		super();
		play([h2d.Tile.fromColor(0)]);

		//	bg
		var bg = new h2d.Bitmap(h2d.Tile.fromColor(Game.DARK, 96, 31), anim);

		ldoor = new h2d.Bitmap(game.tiles.sub(96, 96, 33, 32), anim);
		ldoor.x = 16;

		rdoor = new h2d.Bitmap(game.tiles.sub(128, 96, 32, 32), anim);
		rdoor.x = 48;

		// fg
		new h2d.Bitmap(game.tiles.sub(0, 96, 96, 32), anim);

	}


	function set_open(b) {
		if( open == b )
			return b;
		open = b;
		hxd.Res.door.play();
		return b;
	}

	public dynamic function onChange() {
	}

	override function update(dt:Float) {
		if( open ) {
			if( opening < 1 ) {
				opening += 0.04 * dt;
				if( opening > 1 ) {
					opening = 1;
//					if( game.step == 5 )
//						y++;
					onChange();
				}
			}
		} else {
			if( opening > 0 ) {
				opening -= 0.02 * dt;
				if( opening < 0 ) {
					opening = 0;
//					if( game.step == 6 )
//						y--;
					onChange();
				}
				switch( game.step ) {
				case 5:
					x += dt * 2;
				case 6:
					x -= dt * 2;
				}

			}
		}

		ldoor.x = Std.int(16 - opening * 24);
		rdoor.x = Std.int(48 + opening * 24);

	}

}