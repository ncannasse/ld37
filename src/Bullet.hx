class Bullet extends Entity {

	var speed = 1 + hxd.Math.srand(0.1);

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
			y -= dt * speed;

			if( y < -5 ) {
				remove();
				break;
			}
		}
	}

}