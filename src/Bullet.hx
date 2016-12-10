class Bullet extends Entity {

	public function new() {
		super();
		var t = h2d.Tile.fromColor(Game.DARK, 3, 3);
		t.dx = -1;
		t.dy = -1;
		play([t]);
	}

	override public function update(dt:Float) {
		for( i in 0...8 ) {
			if( checkHitHero(0,-1) ) {
				remove();
				break;
			}
			y -= dt;

			if( y < -5 ) {
				remove();
				break;
			}
		}
	}

}