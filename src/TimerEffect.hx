import Common;

class TimerEffect extends Ent
{
	public var code:SkillCode;
	public var cooldown:Int;
	public var troup:Troup;
	
	public function new(code, troup:Troup) 
	{
		super(0, 0);
		ray = 8;

		cooldown = Skill.getExecutingTime(code);
		this.code = code;
		this.troup = troup;
		
		
		switch(code) {
			case PIEGE: anim = new h2d.Anim(game.gfx.states.stun, 5, troup.icone);
			case POISON: anim = new h2d.Anim(game.gfx.states.poison, 5, troup.icone);
			case SPRINT: anim = new h2d.Anim(game.gfx.states.sprint, 5, troup.icone);
			case COUP_BOUCLIER: anim = new h2d.Anim(game.gfx.states.stun, 5, troup.icone);
			case LEVER_BOUCLIER: anim = new h2d.Anim(game.gfx.states.bouclier, 5, troup.icone);
			case CHARGE_FRENETIC: anim = new h2d.Anim(game.gfx.states.charge, 5, troup.icone);
			case BERSERK: anim = new h2d.Anim(game.gfx.states.berserk, 5, troup.icone);
			case DODO: anim = new h2d.Anim(game.gfx.states.dodo, 5, troup.icone);
			case SCAN: anim = new h2d.Anim(game.gfx.states.scan, 5, troup.icone);
			case POWER_AURA: anim = new h2d.Anim(game.gfx.states.powerAura, 5, troup.icone);
			default: anim = null;
		}
			
		if(anim != null) {
			anim.parent = troup.icone;
			anim.colorKey = 0xFFFFFFFF;
			anim.x = -2 * ray;
			anim.y = -25;
			anim.scale(0.6);
		}
		
		troup.timeEffect.push(this);
	}

	static public function getTimerEffect(code, troup:Troup) {
		for (t in troup.timeEffect) if (t.code == code) { return t.cooldown > 0; }
		return false;
	}
	
	override public function update(dt:Float) {
		if(anim != null) {
			var place = 0;
			for (s in troup.timeEffect) {
				if (s == this) anim.x = (place-1) * ray * 2;
				else place++;
			}
		}
		if (cooldown > 0) cooldown--;
		else {
			troup.timeEffect.remove(this);
			kill();
		}
	}
	
	
}