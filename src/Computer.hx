package;

class Computer extends Entity {

	public function new() {
		super();
		x = 209;
		y = 49;
		var t = h2d.Tile.fromColor(Game.DARK, 1, 1, 0.5);
		play([t, t.sub(0,0,0,0)], 6);
	}

}