class Door extends Entity {

	var ldoor : h2d.Object;
	var rdoor : h2d.Object;
	var opening : Float = 0.;
	var fg : h2d.Bitmap;
	public var open(default,set) : Bool = false;

	public function new() {
		super();
		play([h2d.Tile.fromColor(0, 0.)]);
		game.root.add(anim, 1);

		//	bg
		var bg = new h2d.Bitmap(h2d.Tile.fromColor(Game.DARK, 92, 31), anim);
		bg.x = 4;

		ldoor = new h2d.Bitmap(game.tiles.sub(96, 96, 33, 32), anim);
		ldoor.x = 16;

		rdoor = new h2d.Bitmap(game.tiles.sub(128, 96, 32, 32), anim);
		rdoor.x = 48;

		// fg
		fg = new h2d.Bitmap(game.tiles.sub(160, 96, 96, 64));
		game.root.add(fg, 3);

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

	override public function remove() {
		super.remove();
		fg.remove();
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

		fg.x = anim.x;
		fg.y = anim.y;
	}

}