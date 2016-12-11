package;

class Eye extends Entity {

	var baseX : Int;
	var baseY : Int;

	public function new(x,y) {
		super();
		this.x = this.baseX = x;
		this.y = this.baseY = y;
		play([h2d.Tile.fromColor(0xAD9393)]);
	}

	override public function update(dt:Float) {
		super.update(dt);
		if( game.hero.x < 200 )
			x = baseX - 1;
		else if( game.hero.x  > 400 )
			x = baseX + 1;
		else
			x = baseX;

		if( game.hero.y <  100 )
			y = baseY - 1;
		else if( game.hero.y > 200 )
			y = baseY + 1;
		else
			y = baseY;

	}

}