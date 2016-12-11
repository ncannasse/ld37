
class SkewShader extends hxsl.Shader {
	static var SRC = {
		@:import h3d.shader.Base2d;
		function vertex() {
			absolutePosition.y += absolutePosition.x * 0.3 * abs(absolutePosition.y - 200) / 200;
		}
	}
}

class ComputerPlay extends Entity {

	var tf : h2d.Text;
	var input : h2d.TextInput;

	public function new() {
		super();

		game.play = this;
		anim.play([h2d.Tile.fromColor(Game.DARK, 200, 150)]);
		tf = new h2d.Text(hxd.res.DefaultFont.get(), anim);
		tf.x = 5;
		tf.y = 2;
		tf.textColor = Game.BG;
		tf.text = "";
		anim.scaleX = 1.3;
		anim.rotate( -1.5);
		anim.x = 20;
		anim.y = 240;
		anim.filters = [new h2d.filter.Glow(Game.DARK, 0.)];
		anim.addShader(new SkewShader());
		anim.alpha = 0;
		game.event.waitUntil(function(dt) {
			anim.alpha += dt * 0.01;
			if( anim.alpha > 1 ) {
				anim.alpha = 1;
				wait();
				return true;
			}
			return false;
		});
		input = new h2d.TextInput(tf.font, anim);
		@:privateAccess input.interactive.visible = false;
		input.visible = false;
		input.onChange = function() {
			hxd.Res.keyb.play();
		};
	}

	function wait() {
		pr("x@home:~$ ", function() {
			input.y = tf.y + tf.textHeight - tf.font.lineHeight;
			input.x = tf.x + tf.calcTextWidth((tf.text:String).split("\n").pop());
			input.text = "";
			input.visible = true;
		});
	}

	function pr( s : String, onEnd : Void -> Void ) {
		if( tf.text != "" )
			tf.text += "\n";
		var lines = (tf.text:String).split("\n");
		while( lines.length > 9 ) {
			lines.shift();
			tf.text = lines.join("\n");
		}
		var t = 0.;
		var pos = 0;
		game.event.waitUntil(function(dt) {
			t += dt;
			if( t > 1 ) {
				t--;
				if( pos >= s.length ) {
					onEnd();
					return true;
				}
				if( hxd.Res.keyb.lastPlay < haxe.Timer.stamp() - 0.05 ) hxd.Res.keyb.play();
				tf.text += s.charAt(pos++);
			}
			return false;
		});
	}

	var hasCat = true;
	public var volume = 1.;

	function runCommand(cmd:String) {
		var args = ~/ +/g.split(cmd);
		switch( args.shift() ) {
		case "help":
			pr("Use [exit] [ls] [rm]", function() pr("Nobody will help you.", wait));
		case "exit":
			function goodNight() {
				pr("Good night.", goodNight);
			}
			goodNight();
			game.event.wait(2, function() game.hero.die());
		case "ls":
			var files = ["subject.dat", "door.dat", "virus.bin"];
			if( game.door == null )
				files.remove("door.dat");
			if( args.shift() == "-all" ) {
				files.push("lock.root");
				if( hasCat ) files.push("cat.jpg");
			}
			function listFiles() {
				var f = files.shift();
				if( f == null ) {
					wait();
					return;
				}
				pr("  "+f, listFiles);
			}
			listFiles();
		case "rm":
			switch( args[0] ) {
			case null:
				hxd.Res.error.play();
				pr("Usage: rm [file]", wait);
			case "subject.dat":
				pr("Erasing subject...", function() {
					game.hero.die();
				});
			case "door.dat" if( game.door != null ):
				pr("Erasing door...", function() {
					game.door.remove();
					game.door = null;
					pr("No more exit found", wait);
				});
			case "virus.bin":
				pr("Erasing virus...", function() {
					game.event.wait(1, function() {
						function loop(i) {
							hxd.Res.error.play();
							if( i++ < 10 )
								pr("  ls -all", loop.bind(i));
							else
								pr("Virus could not be deleted", wait);
						}
						loop(0);
					});
				});
			case "cat.jpg" if( hasCat ):
				pr("Thanks.", wait);
			case "lock.root":
				pr("Erasing lock...", function() {
					game.event.wait(1, function() {
						if( game.door == null ) {
							hxd.Res.error.play();
							pr("Door not found", function() game.event.wait(1, function() pr("Erasing curious subject.", function() game.hero.die())));
						} else {
							game.door.open = true;

							for( x in 0...30 )
								for( y in 0...80 )
									game.collide.setPixel(x + 210, y + 260, 0);

							pr("Door opened", function() {
								game.hero.state = Move; // unlock
								@:privateAccess game.hero.anim.frames = game.hero.anims.walkDown;
								function loop() {
									if( anim.parent == null ) return;
									if( volume > 0 ) hxd.Res.error.play(false, volume);
									pr("Subject is escaping!", loop);
								}
								loop();

							});
						}
					});
				});
			default:
				hxd.Res.error.play();
				pr("File not found", wait);
			}
		case "nobody":
			pr("Follow virus", wait);
		default:
			hxd.Res.error.play();
			pr("Unknown command", function() pr("Use [help]", wait));
		}
	}

	override public function update(dt:Float)  {
		if( input.visible && !input.hasFocus() ) {
			var cmd = StringTools.trim(input.text);
			if( cmd != "" ) {
				tf.text += cmd;
				input.visible = false;
				runCommand(cmd);
				return;
			}
			input.focus();
			input.text = "";
			input.cursorIndex = 0;
		}
	}


}