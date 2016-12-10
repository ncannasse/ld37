
class Pic extends Entity {

	static var ANIM;

	public var active = true;

	public function new(x, y){
		super();
		this.x = x;
		this.y = y;
		if( ANIM == null )
			ANIM = [for( t in game.tiles.sub(0, 128, 112, 16).split() ) { t.dx = -8; t.dy = -8; t; }];
		play(ANIM);
		anim.speed = 0;
		anim.loop = false;
		anim.alpha = 0;
		game.event.waitUntil(function(dt) {
			anim.alpha += ((x + 100) / 4000) * dt;
			if( anim.alpha > 1 ) {
				anim.alpha = 1;
				return true;
			}
			return false;
		});
	}

	public function hit() {
		anim.speed = 20;
		if( hxd.Res.click.lastPlay < haxe.Timer.stamp() - 0.05 ) hxd.Res.pic.play();
	}

	public function hide(onEnd) {
		active = false;
		var a = ANIM.copy();
		a.reverse();
		play(a, null, onEnd);
		if( hxd.Res.click.lastPlay < haxe.Timer.stamp() - 0.05 ) hxd.Res.pic.play();
	}

}