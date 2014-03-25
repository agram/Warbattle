import Common;

class Fight extends Ent
{
	public static var COEF_BONUS = 3;
	
	var t1:Troup;
	var t2:Troup;
	
	public function new(t1:Troup, t2:Troup) 
	{
		super(x, y, 1000);

		this.t1 = t1;
		this.t2 = t2;
		
		x = (t2.icone.x + t1.icone.x) / 2;
		y = (t2.icone.y + t1.icone.y) / 2;	

		anim.play(game.gfx.particule.fight);
		anim.x = - 4;
		anim.y = - 4;	
	}
	
	override function update (dt:Float) {
		if (t1.dead || t2.dead ) {
			kill();
			return;
		}
		
		x = (t2.icone.x + t1.icone.x) / 2;
		y = (t2.icone.y + t1.icone.y) / 2;
		
		// resoudre le combat ici, sinon cela signifie simplement que l'unité est au contact avec une autre unité et qu'elle ne peut
		// pas s'occuper de cette unité pour l'instant. En effet, l'ordre de charge est important.
		if ( t1.fights[0] == t2) fight(t1, t2);
		if ( t2.fights[0] == t1) fight(t2, t1);
	}
	
	static public function fight(t1:Troup, t2:Troup) {
		if (t1.isStun() || t1.isFourmi()) return;
		
		if (t1.cooldownScrum > 0) {
			t1.cooldownScrum--;
			return;
		}
			
		var bonus = t2.fights.length - 1;
		var damage = t1.caracs.scrum.damage * ( 1 + bonus / COEF_BONUS);
		damage = t2.formationSerre(damage);
		if (t1.getPoweraura()) damage *= 1.1;
		t2.looseLife(damage, PHYSIQUE);
		t1.cooldownScrum = t1.caracs.scrum.attackSpeed;
		if (t1.isPoison()) t1.cooldownScrum * 2;
		if (t1.isCurse()) t1.cooldownScrum * 2;


	}
}