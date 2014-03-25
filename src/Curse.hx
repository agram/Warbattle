import Common;

class Curse extends Ent
{

	var cooldown:Int;
	
	public function new(x, y) 
	{
		super(x, y);
		cooldown = 120;
		
		width = 96;
		height = 96;
		
		anim.play(game.gfx.particule.curse);
		anim.x = -48;
		anim.y = -48;
	}

	override public function update(dt:Float) {
		cooldown--;
		if (cooldown <= 0) kill();
	}	
	
	override public function onCollide(e:Ent) {
		var f = e.toType(TROUP);
		if (f == null) return;
		
		if (Math.abs(x - f.x) < width && Math.abs(y - f.y) < height)
			new TimerEffect(CURSE, f.troup);
	}	
}