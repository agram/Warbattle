import Common;

class Troup extends h2d.Sprite
{
	public static var RAY = 16;
	var game:Game;
	
	public var icone:IconeTroup;
	
	static var NUM = 0;
	static var SPEED_SLOWER = 15;
	
	public var ray:Int;
	public var code:CodeTroup;
	var gfx = h2d.Bitmap;
	
	public var player:Int;
	public var selected:Bool;
	public var numero:Int;
	
	public var skills:Array<Skill>;
	
	public var goal:Goal;

	public var fights:Array<Troup>;
	public var firing:Troup;
	public var charging:Troup;
	var cooldownRange:Int;
	public var cooldownScrum:Int;
	public var pv:Float;
	public var dead:Bool;
	public var vu:Bool;
	
	public var mObstacle: Tools.MyPoint;
	
	var timerMove:Float;

	var path:Path;

	public var attackMove:Bool;
	
	public var tabBrezenham:Array<Bool>;
	
	public var poison:Bool;

	public var timeEffect:Array<TimerEffect>;
	
	public var deployed:Bool;
	
	public var iDeploy:h2d.Interactive;
	
	public function new(x, y, code, player) 
	{
		super();
		
		game = Game.inst;
		
		this.x = x;
		this.y = y;
		numero = NUM++;
		this.code = code;
		this.player = player;
		ray = RAY;
		
		makeCaracs();
	
		goal = null;
		mObstacle = null;
		fights = [];
		firing = null;
		cooldownRange = 0;
		cooldownScrum = 0;
		pv = caracs.life;
		dead = false;
		vu = true;
		
		timerMove = 0;
		
		path = null;

		icone = new IconeTroup(this);
		
		tabBrezenham = [];

		game.board.add(this, Const.L_UNIT);
		
		attackMove = false;
		
		timeEffect = [];
		
		deployed = false;
		iDeploy = null;
		
	}
	
	public function initSkills() {
		skills = [];
		skills.push(new Skill(this, caracs.skills.first));
		skills.push(new Skill(this, caracs.skills.second));
	}
	
	public function update(dt:Float) {
		if (!game.start || dead ) return;
		
		for (s in skills) 
			if (s !=  null) 
				s.update();
		
		if (goal != null && goal.isTroup && goal.target.dead) {
			goal.kill();
			goal = null;
		}

		if (isPlayer() && goal != null) {
			if(selected && !isFourmi()) goal.anim.visible = true;
			else goal.anim.visible = false;
		}
		
		if (isPoison()) looseLife(0.5, MAGIC);
		if (isEnd(BERSERK)) pv = 1;
		if (isEnd(METAMORPHOSE)) icone.setAnim();
		if (isEnd(CLOACK)) icone.anim.alpha = 1;
		if (isEnd(MINDCONTROL)) revertControl();
		
		if (isStun() || isFourmi()) return;
		
		deplace();
		
		// Pour les troupes ennemis, on recherche une nouvelle cible aléatoirement toutes les 20 frames
		if (!isPlayer() && charging == null && Std.random(20) == 0 ) searchTarget();

		if (attackMove || goal == null) {
			firing = fire();
			charging = charge();
		}
		else if (goal.isTroup) {
			firing = fire(goal.target);
			charging = charge(goal.target);
		}
		
		if (charging != null && charging.code == ARCHER) {
			tirBarrage(charging);
		}
	}
	
	public inline function isPlayer() { return player == 1; }
	
	public function activateForDeploy() {
		iDeploy = new h2d.Interactive(ray * 2, ray * 2, this.icone);
		iDeploy.enableRightButton = true;
		iDeploy.x = -ray;
		iDeploy.y = -ray;
		iDeploy.onClick = function (e) {
			game.messageSkills.texte.text = 'Description : \n' + getDescription() + '\n\nCaractéristiques : \n\n' + getCaracteristique();
			if (isPlayer()) {
				if(e.button == 0) select(); 
				else {
					game.player.selectedTroup.deployed = false;
					x = 740;
					y = numero * 33 + 20;
					icone.x = 740;
					icone.y = numero * 33 + 20;
				}
			}
		}
	}
	
	public function activate() {
		// Zone interactive sur le sprite
		var i = new h2d.Interactive(icone.width, icone.height, this.icone);
		i.enableRightButton = true;
		i.propagateEvents = true;
		
		i.x = -ray;
		i.y = -ray;
		
		i.onMove = function (e) { 
			if (game.modeAttackMove || game.player.selectedSkill != null) i.cursor = Hide; 
			else i.cursor = Move;
			
			game.moveCursor(e, icone.x - ray, icone.y - ray); 
			if (game.zoneSelection.begin != null) game.zoneSelection.end = { x: e.relX + x - ray * 1.5, y: e.relY + y - ray * 1.5 }; 
		};
		i.onClick = function (e) { 
			if(e.button == 0) {
				if (game.player.selectedSkill != null) {
					if (isPlayer()) {
						game.player.selectedSkill.actionOnAlly(this);
					}
					else if (vu) {
						game.player.selectedSkill.actionOnEnnemy(this);
					}
					return ;
				}
				else {
					if (isPlayer()) 
						select(game.keysActive.shift); 
				}
			}
			else {
				e.propagate = false;
				if (game.player.selectedSkill != null) game.player.selectedSkill.deactivate();
				else if (game.modeAttackMove) game.deactivateAttackMove();
				else if(!isPlayer()) {
					for (t in game.player.troups) if (t.selected) {
						if (t.goal != null) t.goal.kill();
						t.goal = Goal.setGoalTroup(this, t);
					}
				}
				else e.propagate = true;
			}
		};
		
		updateMObstacle();
	}
	
	// Chaque unité "noircit" une surface correspondant au double de sa surface. Cela permet de ne tester les déplacement que du centre d'une troupe
	function updateMObstacle() {
		var m = getMObstacle();

		// Pour éviter que les centres se touchent, je considère un rond de 2 rayon de large
		var a = Math.max(0, x - 2 * ray);
		for (i in 0...4 * ray) {
			var b = Math.max(0, y - 2 * ray);
			for (j in 0...4 * ray) {
				// vérification sur la distance pour traiter un rond et non un carré.
				var c = Std.int(a + Const.MAP_WIDTH * b);
				if (m[c] > -1 && Tools.distanceSquare(a, x, b, y) < ray * ray * 4) {
					m[c] += 100;
					mObstacle = getPoint(a, b, mObstacle);
				}
				b++;
				if (b >= Const.MAP_HEIGHT - 1) break;
			}
			a++;
			if (a >= Const.MAP_WIDTH - 1) return;
		}
		
	}
	
	public function getPoint(x, y, next = null)
	{
		if (Game.cachePoint == null) {
			return new Tools.MyPoint (x, y, next); 
		}
		else {
			var a = Game.cachePoint;
			Game.cachePoint = Game.cachePoint.next;
			a.x = x;
			a.y = y;
			a.next = next;
			return a;
		}
	}

	public function freeAll(l:Tools.MyPoint) {
		if (l == null) return null;
		var p = l;
		while (p.next != null) p = p.next;
		p.next = Game.cachePoint;
		Game.cachePoint = l;
		return null;
	}
	
	public function select(add = false) {
		if (isFourmi()) return;
		
		if (!add) for (t in game.player.troups) if (t != this && t.selected) t.unselect();
		
		if(game.player.selectedSkill != null) game.player.selectedSkill.deactivate();
		if(game.modeAttackMove) game.deactivateAttackMove();
		
		selected = true;
		icone.setAnim();
		
		if (!game.start) {
			game.player.selectedTroup = this;
			return;
		}
		
		for (sz in game.skillZones) sz.deactivated();
		
		var afficheSkills = true;
		for (t in game.player.troups) if (t != this && t.selected) afficheSkills = false;
		if (afficheSkills) {
			game.player.selectedTroup = this;
			game.skillZones[0].show(skills[0]);
			game.skillZones[1].show(skills[1]);
		}
		else {
			game.player.selectedTroup = null;
			SkillZone.hideAll();
		}
	}
	
	public function unselect() {
		selected = false; 
		if (game.start) SkillZone.hideAll();
		icone.setAnim();		
	}
	
	public function setGoal(relX:Float, relY:Float, attackMove = false) {
		
		firing = null;
		charging = null;
		
		var x = Std.int(relX);
		var y = Std.int(relY);
		var i = Std.int(x + Const.MAP_WIDTH * y);
		
		if ( (isPlayer() && game.player.obstacle[i] > -1) 
		|| (!isPlayer() && game.opponent.obstacle[i] > -1) ) {
			if (goal != null) goal.kill();
			goal = new Goal(x, y, this);		
			this.attackMove = attackMove;
			return true;
		}
		
		return false;
	}
	
	public function deplace () {
			if ( isFighting() ) return; 
			if ( firing != null ) return;
		
		// Les unités ne se déplacent pas forcément à toutes les frames.
		// Une unités avec une vitesse de 10 (vitesse maximum) se déplace à toutes les frames
		// Une unité avec une vitesse de 1 (vitesse minimum) se déplace 1 frame sur 10, soit maximum 6 frames par secondes
		if (timerMove > 0) {
			timerMove--;
			return ;
		}
		
		var speed:Float;
		if (isLeverBouclier()) speed = caracs.speed /2;
		else if (isChargeFrenetic()) speed = caracs.speed * 2;
		else speed = caracs.speed;
		
		if (isSprint()) speed *= 1.5;
		if (isCurse()) speed /= 2;
		if (isPoison()) speed /= 2;
		
		timerMove = SPEED_SLOWER - speed;

		// tout d'abord, on vide l'existant de la présence de la troupe
		var p = mObstacle;
		var m = getMObstacle();
		while (p != null) {
			m[Std.int(p.x + Const.MAP_WIDTH * p.y)] -= 100;
			p = p.next;
		}
		mObstacle = freeAll(mObstacle);
		
		// Dans le cas où l'on suis une troupe qui n'est plus en vu, on suis la derniere position enregistrée de la cible.
		var xx:Float;
		var yy:Float;
		if (charging != null) {
			xx = charging.x;
			yy = charging.y;
		}
		else if (goal != null) {
			if(goal.isTroup) {
				if (goal.target.vu == true) {
					xx = goal.lastGoalX = goal.target.x;
					yy = goal.lastGoalY = goal.target.y;
				}
				else {
					xx = goal.lastGoalX;
					yy = goal.lastGoalY;
				}
			}
			else {
				xx = goal.x;
				yy = goal.y;
			}
		}
		else return;
		
		path = new Path(Std.int(xx), Std.int(yy), Std.int(x), Std.int(y), this);
		
		x = path.point.x;
		y = path.point.y;
		
		if ( goal != null) 
			if ( (goal.isTroup && goal.target.dead) || (Math.abs(x - xx) < 4 && Math.abs(y - yy) < 4) )
				goal.kill();

		updateMObstacle();
	}
	
	public function isFighting() {
		return fights.length > 0;
	}
	
	public function onCollide(e:Troup) {
		
		for (f in fights) if (f == e) return ;
		
		if ( isPlayer() != e.isPlayer() && Tools.distanceSquare(x, e.x, y, e.y) < ray * ray + e.ray * e.ray ) {
			fights.push(e);
			e.fights.push(this);
			new Fight(this, e);
		}
	}
	
	public function charge (target:Troup = null) {
		if (isCloack()) return null;
		if (charging != null) { 
			if (!charging.dead) charging = null;
			else return null;
		}
		
		if (caracs.scrum.range == 0 || isFighting()) return null;

		var distance = -1.;
		var troup = null;
		
		if(target == null) {
			for (t in ennemyTroups()) {
				if (t.vu) {
					var d = Tools.distanceSquare(x, t.x, y, t.y);
					if ( d < caracs.scrum.range * caracs.scrum.range && (distance < 0 || distance > d) ) {
						distance = d; 
						troup = t;
					}
				} 
			}
		}
		else {
			var d = Tools.distanceSquare(x, target.x, y, target.y);
			if ( d < caracs.scrum.range * caracs.scrum.range)
				troup = target;
		}
		
		return troup;
	}
	
	public function fire(target:Troup = null) {
		if (isStun() || isFourmi()) return null;
		
		if (caracs.longDistance.range == 0 || isFighting()) return null;
		
		if (cooldownRange != 0) { 
			cooldownRange--;  
			return firing; 
		}
		
		var distance = -1.;
		var troup = null;
		if(target == null) {
			for (t in ennemyTroups()) {
				//if (!t.isFighting() && t.vu) {
				if (t.vu) {
					var d = Tools.distanceSquare(x, t.x, y, t.y);
					if ( d < caracs.longDistance.range * caracs.longDistance.range && (distance < 0 || distance > d) ) {
						distance = d; 
						troup = t;
					}
				} 
			}
		}
		else {
			var range:Float = caracs.longDistance.range;
			var d = Tools.distanceSquare(x, target.x, y, target.y);
			if ( d < range * range)	troup = target;
		}
		
		if (troup == null) return null;
		
		cooldownRange = caracs.longDistance.attackSpeed;
		if (isPoison()) cooldownRange * 2;
		if (isCurse()) cooldownRange * 2;
		
		new Arrow(x, y, this, troup, NORMAL);
		
		return troup;
	}
	
	public function looseLife(nb:Float, typeDamage:TypeDamage) {
		if (code == HERO) {
			var suite = true;
			for (t in timeEffect) if (t.code == POWER_AURA) {
				suite = false; t.cooldown = Skill.getExecutingTime(POWER_AURA);
			}
			if(suite) new TimerEffect(POWER_AURA, this);
			
		}
		else if (getPoweraura()) nb *= 0.9;
		
		if (isCurse()) nb = nb * 3;
		if (isFourmi()) nb = nb * 3;		
		switch(typeDamage) {
			case PHYSIQUE: nb = nb * (100 - caracs.armor.physique) / 100;
			case MAGIC: nb = nb * (100 - caracs.armor.magique) / 100;
			case TIR: nb = nb * (100 - caracs.armor.tir) / 100;
		}
		if (nb > 0) icone.animLooseLife = Std.int(Math.min(20, icone.animLooseLife + nb));

		pv -= nb;
		if (pv < 0)	{
			if (code == TROLL && !dead) {
				var s = getSkill(BERSERK);
				if (s.cooldown <= 0) berserk();
			}
			if (isBerserk())
				pv = 1;
			else {
				if (code == HERO) {
					var s = getSkill(RESURECT);
					if(s != null && s.cooldown <= 0) {
						s.cooldown = s.cooldownMax;
						if(isPlayer()) {
							game.player.resurectHero = {
								cooldown: 150,
								x: x,
								y: y,
							};
						}
						else {
							game.opponent.resurectHero = {
								cooldown: 150,
								x: x,
								y: y,
							}
						}
					}
				}
				dead = true;
			}
		}
	}
	
	public function use(code:SkillCode) {
		var s = getSkill(code);
		if(s == null) throw (code + ' est null');
		s.cooldown = s.cooldownMax;
	}
	
	public function destroy(skull = true) {
		dead = true;
		icone.destroy();

		if (game.player.selectedTroup == this) {
			if (game.player.selectedSkill != null) game.player.selectedSkill.deactivate();
		}
		
		if (skull) {
			var anim = new h2d.Anim(this);
			anim.play(game.gfx.particule.death);
			anim.colorKey = 0xFFFFFFFF;
			anim.scale(0.5);
			anim.x = x - ray;
			anim.y = y - ray;
			
			game.board.add(anim, Const.L_GROUND);
		}
	
		if (goal != null) goal.kill();
		if(isPlayer()) game.player.troups.remove(this);
		else game.opponent.troups.remove(this);
		for (t in fights) {
			t.fights.remove(this);
		}
		fights = [];
		if (selected) SkillZone.hideAll();
		
		if(skull) {
			if (isPlayer()) game.player.initLivingTroups();
			else game.opponent.initLivingTroups();
		}
	}

	inline public function getMObstacle () {
		return (isPlayer()) ? game.player.obstacle : game.opponent.obstacle;
	}
	
	inline public function ally() {
		return (isPlayer()) ? game.player : game.opponent;
	}
	
	inline public function ennemy() {
		return (!isPlayer()) ? game.player : game.opponent;
	}
	
	inline public function allyTroups() {
		return (isPlayer()) ? game.player.troups : game.opponent.troups;
	}
	
	inline public function ennemyTroups() {
		return (!isPlayer()) ? game.player.troups : game.opponent.troups;
	}
	
	// Pour faire simple, je recherche la troupe la plus proche (seulement si la troupe a perdu sa cible.
	// Si la troupe la plus proche est trop loin (plus loin que 1/2 écran), la troupe avance betement tout droit
	function searchTarget(noLimite = false) {

		var d = -1.;
		var target = null;
		var distance = -1.;
		for (t in ennemyTroups()) {
			if (!noLimite && (t.x - 225 > x || t.x + 225 < x || t.y - 225 > y || t.y < 225) )
				distance = 50000;
			else 
				distance = ( t.x - x ) * ( t.x - x ) + ( t.y - y ) * ( t.y - y );
			 
			if (d == -1 || d > distance) {
				d = distance;
				target = t;
			}
		}
		if (goal != null) {
			if(target != goal.target)
				goal.kill();
			else
				return;
		}
		
		if (d == -1) return;
		
		if (noLimite || d < 50000) {
			goal = Goal.setGoalTroup(target, this);
			attackMove = true;
		}
		else
		{
			var o = ally();
			var a = Std.int(y + 40);
			for (yy in a...Const.MAP_HEIGHT - 100) {
				if(o.obstacle[Std.int(x + Const.MAP_WIDTH * yy)] > -1) {
					goal = new Goal(x, yy, this);
					attackMove = true;
					return;
				}
			}
		}
	}
	
	public function getSkill(code:SkillCode) {
		for (s in skills) if (s.code == code) return s;
		return null;
	}
	
	public function isEnd(code) {
		for (t in timeEffect) if (t.code == code) { return t.cooldown == 1; }
		return false;
	}
	
	public function sprint() {
		new TimerEffect(SPRINT, this);
		use(SPRINT);
	}
	
	public function tirBarrage (troup:Troup) {
		if (TimerEffect.getTimerEffect(TIR_BARRAGE, troup)) return;
		new TimerEffect(TIR_BARRAGE, troup);
		new Arrow(x, y, troup, this, BARRAGE);
		troup.use(TIR_BARRAGE);
	}
	
	public function leverBouclier (damage:Float) {
		if(! TimerEffect.getTimerEffect(LEVER_BOUCLIER, this)) new TimerEffect(LEVER_BOUCLIER, this);
		return damage / 4;
	}
	
	public function coupBouclier() {
		new TimerEffect(COUP_BOUCLIER, this);
	}
	
	public function formationSerre(damage:Float) {
		
		if (code == SOLDAT && fights[0].fights.length > 1)
			return damage / 4;
			
		for (t in allyTroups()) {
			if (t != this) 
				if (t.isFighting() && t.fights[0] == fights[0]) {
					return damage / 4;
				}
		}
		
		return damage;
	}
	
	public function attaqueTournoyante() {
		if (!isFighting()) return;
		
		for (t in fights) {
			cooldownScrum = 0;
			Fight.fight(this, t);
		}
		use(ATTAQUE_TOURNOYANTE);
	}
	
	public function piege() {
		new TimerEffect(PIEGE, this);
		looseLife(150, MAGIC);
	}
	
	public function chargeFrenetic() {
		searchTarget(true);
		new TimerEffect(CHARGE_FRENETIC, this);
		use(CHARGE_FRENETIC);
	}
	
	public function berserk() {
		new TimerEffect(BERSERK, this);
		use(BERSERK);
	}
	
	public function cloack() {
		new TimerEffect(CLOACK, this);
		icone.anim.alpha = 0.5;
		use(CLOACK);
	}
	
	public function teleport(x, y) {
		var x = Std.int(x);
		var y = Std.int(y);
		var i = Std.int(x + Const.MAP_WIDTH * y);
		
		if ( (isPlayer() && game.player.obstacle[i] == 0) 
		|| (!isPlayer() && game.opponent.obstacle[i] == 0) ) {
			if (goal != null) goal.kill();
			this.x = x;
			this.y = y;
			this.icone.x = x;
			this.icone.y = y;
			
			use(TELEPORTATION);

			return true;
		}
		
		return false;
	}
	
	public function revertControl() {
		goal = null;
		player = (player == 2) ? 1 : 2;
		var g = allyTroups();
		var h = ennemyTroups();
		h.remove(this);
		g.push(this);
		icone.setAnim();
	}

	public function getPoweraura() { 
		var g = allyTroups();
		for (t in g) {
			if (t.code == HERO && t.isPoweraura() ) return true;
			else return false;
		}
		return false;
	}
	
	inline public function isFourmi() { return TimerEffect.getTimerEffect(METAMORPHOSE, this); }
	inline public function isCloack() { return TimerEffect.getTimerEffect(CLOACK, this); }
	inline public function isSprint() { return TimerEffect.getTimerEffect(SPRINT, this); }
	inline public function isCurse() { return TimerEffect.getTimerEffect(CURSE, this); }
	inline public function isPoison() { return TimerEffect.getTimerEffect(POISON, this); }
	inline public function isBerserk() { return TimerEffect.getTimerEffect(BERSERK, this); }
	inline public function isStun() { return TimerEffect.getTimerEffect(PIEGE, this) || TimerEffect.getTimerEffect(COUP_BOUCLIER, this) || TimerEffect.getTimerEffect(DODO, this) ; }
	inline public function isControl() { return TimerEffect.getTimerEffect(MINDCONTROL, this); }
	inline public function isChargeFrenetic() { return TimerEffect.getTimerEffect(CHARGE_FRENETIC, this); }
	inline public function isLeverBouclier() { return TimerEffect.getTimerEffect(LEVER_BOUCLIER, this); }
	inline public function isPoweraura() { return !dead && TimerEffect.getTimerEffect(POWER_AURA, this); }

	public var caracs: {
		speed:Float,
		longDistance: {
			attackSpeed:Int,
			range:Int,
			damage:Int,
		},
		scrum: {
			attackSpeed:Int,
			damage:Int,
			range:Int,
		},
		life:Int,
		armor: {
			physique:Int,
			tir:Int,
			magique:Int,
		},
		skills: {
			first: SkillCode,
			second: SkillCode,
		},

	};
	
	function makeCaracs () {
		caracs = {
			speed: switch(code) { 
				case CHASSEUR : 10;
				case ARCHER : 10;
				case TANK : 8;
				case SOLDAT : 8;
				case TROLL : 8;
				case MAGICIEN : 4;
				case NECROMANCIEN : 4;
				case ASSASSIN : 10;
				case ORACLE : 4;
				case HERO : 8;
				//case HERO : 15;
				},
			longDistance: {
				attackSpeed: switch(code) { 
					case CHASSEUR : 20;
					case ARCHER : 20;
					case TANK : 0;
					case SOLDAT : 0;
					case TROLL : 0;
					case MAGICIEN : 40;
					case NECROMANCIEN : 40;
					case ASSASSIN : 20;
					case ORACLE : 40;
					case HERO : 0;
					},
				range: switch(code) { 
					case CHASSEUR : 75;
					case ARCHER : 100;
					case TANK : 0;
					case SOLDAT : 0;
					case TROLL : 0;
					case MAGICIEN : 50;
					case NECROMANCIEN : 50;
					case ASSASSIN : 75;
					case ORACLE : 50;
					case HERO : 0;
					},
				damage: switch(code) { 
					case CHASSEUR : 10;
					case ARCHER : 10;
					case TANK : 0;
					case SOLDAT : 0;
					case TROLL : 0;
					case MAGICIEN : 20;
					case NECROMANCIEN : 20;
					case ASSASSIN : 10;
					case ORACLE : 20;
					case HERO : 0;
					},
			},
			scrum: {
				attackSpeed: switch(code) { 
					case CHASSEUR : 40;
					case ARCHER : 40;
					case TANK : 20;
					case SOLDAT : 20;
					case TROLL : 10;
					case MAGICIEN : 40;
					case NECROMANCIEN : 40;
					case ASSASSIN : 10;
					case ORACLE : 40;
					case HERO : 20;
					},
				damage: switch(code) { 
					case CHASSEUR : 10;
					case ARCHER : 10;
					case TANK : 10;
					case SOLDAT : 20;
					case TROLL : 30;
					case MAGICIEN : 5;
					case NECROMANCIEN : 5;
					case ASSASSIN : 30;
					case ORACLE : 5;
					case HERO : 10;
					},
				range: switch(code) { 
					case CHASSEUR : 0;
					case ARCHER : 0;
					case TANK : 50;
					case SOLDAT : 50;
					case TROLL : 70;
					case MAGICIEN : 0;
					case NECROMANCIEN : 0;
					case ASSASSIN : 0;
					case ORACLE : 0;
					case HERO : 50;
					},
			},
			life: switch(code) { 
					case CHASSEUR : 300;
					case ARCHER : 300;
					case TANK : 1000;
					case SOLDAT : 700;
					case TROLL : 500;
					case MAGICIEN : 200;
					case NECROMANCIEN : 200;
					case ASSASSIN : 300;
					case ORACLE : 200;
					case HERO : 800;
				},
			armor: { // % de réduction
				physique: switch(code) { 
					case CHASSEUR : 10;
					case ARCHER : 10;
					case TANK : 30;
					case SOLDAT : 30;
					case TROLL : 10;
					case MAGICIEN : 0;
					case NECROMANCIEN : 0;
					case ASSASSIN : 20;
					case ORACLE : 0;
					case HERO : 20;
				},
				tir : switch(code) { 
					case CHASSEUR : 10;
					case ARCHER : 10;
					case TANK : 50;
					case SOLDAT : 50;
					case TROLL : 10;
					case MAGICIEN : 0;
					case NECROMANCIEN : 0;
					case ASSASSIN : 10;
					case ORACLE : 0;
					case HERO : 20;
				},
				magique: switch(code) { 
					case CHASSEUR : 10;
					case ARCHER : 10;
					case TANK : 10;
					case SOLDAT : 0;
					case TROLL : 0;
					case MAGICIEN : 50;
					case NECROMANCIEN : 50;
					case ASSASSIN : 50;
					case ORACLE : 50;
					case HERO : 30;
				},
			},
			skills: switch(code) { 
					case CHASSEUR : { first: POISON, second: PIEGE} ;
					case ARCHER : { first: TIR_BARRAGE, second: SPRINT} ;
					case TANK : { first: LEVER_BOUCLIER, second: COUP_BOUCLIER} ;
					case SOLDAT : { first: FORMATION_SERREE, second: ATTAQUE_TOURNOYANTE} ;
					case TROLL : { first: CHARGE_FRENETIC, second: BERSERK} ;
					case MAGICIEN : { first: TELEPORTATION, second: FIREBALL} ;
					case NECROMANCIEN : { first: CURSE, second: METAMORPHOSE} ;
					case ASSASSIN : { first: CLOACK, second: ASSASSINAT} ;
					case ORACLE : { first: DODO, second: SCAN} ;
					case HERO : { first: POWER_AURA, second: RESURECT} ;
				},
		};
	}
	
	public function getDescription () {
		return switch(code) {
			case CHASSEUR : 'Le Chasseur harass ces ennemis à distance\nPoison : blesse et ralentit l\'ennemi\nPiège : blesse et assome l\'ennemi';
			case ARCHER : 'L\'Archer attaque à distance\nTir de Barrage : pour contrer les charges\nSprint : pour courir vite';
			case TANK : 'Le Tank est une armure\nLever de Bouclier : ralentit mais protège des flèches\nCoup de Bouclier : blesse et assome';
			case SOLDAT : 'Le Soldat est un soutien en mélée\nFormation Sérrée : Protège les alliés en mélée\nCleave : blesse chaque ennemi dans la mélée';
			case TROLL : 'Le Troll ne cherche que à taper\nCharge Frénétique : charger l\'ennemi le plus proche\nBerserk : l\'empeche de mourir';
			case MAGICIEN : 'Le Magicien combat de loin\nTéléportation : l\'emmene où il vaut\nBoule de Feu : brule ses ennemis';
			case NECROMANCIEN : 'Le Nécromancien gène tout le monde\nMalédiction : ralentit et rend faible les troupes\nMetaporphose : transforme en fourmi';
			case ASSASSIN : 'Le Fantome est un assassin\nCamouflage : rend invisible\nAssassinat : si invisible, inflige de gros dégats';
			case ORACLE : 'L\'Oracle est prescient\nSommeil : endort un ennemi\n6ième sens : révèle tous les secrets';
			case HERO : 'Le Héro motive l\'armée\nAura de Puissance : booste les alliés\nRésurrection : ramène le héros à la vie';
			default: '';
		}
	}
	
	public function getCaracteristique() {
		return switch(code) {
			case CHASSEUR : 'Attaque à distance, fragile\nHarass et controle à distance';
			case ARCHER : 'Attaque à distance, fragile\nSe protège et fuit';
			case ASSASSIN : 'Attaque à distance, fragile\ndégâts énorme surtout Assassinat avec Camouflage';
			
			case TANK: 'Unités de mélée, beaucoup de PV et d\'armure\nGrosse défense contre les tirs\nTrès lent surtout contre les tirs';
			case SOLDAT : 'Unités de mélée, beaucoup de PV et d\'armure\nSupport des unités en mélée.';
			case TROLL : 'Unités de mélée, beaucoup de PV\nGros dégâts, faculté à ne pas mourir';
			case HERO : 'Unité de mélée\nSupporte les unités proches\nRevit à pleine santé s\'il meurt';
			
			case MAGICIEN : 'Unité de soutien magique, fragile\nGros dégâts de zone';
			case NECROMANCIEN : 'Unité de soutien magique, fragile\nUnité de renfort et de controle\nPeu efficace si seul';
			case ORACLE : 'Unité de soutien magique, fragile\nUnité de renfort et de controle\nPeu efficace si seul';
			
			default: '';
		}
	}
}