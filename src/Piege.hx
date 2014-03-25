import Common;

class Piege extends Ent
{
	public var player:Bool;
	public var actif:Bool;
	
	var cooldownPiege:Int;
	
	public function new(x, y, player)  {
		super(x, y, Const.L_UNIT);
		this.player = player;
		
		anim.play(game.gfx.particule.trap);
		anim.x = -8;
		anim.y = -8;
		
		ray = 8;
		
		visible = player;
		
		actif = true;
	}
	
	override public function update(dt:Float) {
		if (cooldownPiege > 1) {
			cooldownPiege--;
			return ;
		}
		else if (cooldownPiege == 1) {
			kill();
			return;
		}
	}
	
	override public function onCollide (e:Ent) {
		if (!actif) return;
		
		var f = e.toType(TROUP);
		if (f == null) return;
		
		if (f.troup.isPlayer() == player) return;
		
		if (Tools.distanceSquare(f.x, x, f.y, y) > ( ray + f.ray ) * ( ray + f.ray )) return;
		
		visible = true;
		
		f.troup.piege();
		
		actif = false;
		
		anim.alpha = 0.3;
	}
	
	override public function kill() {
		game.traps.remove(this);
		super.kill();
	}
}