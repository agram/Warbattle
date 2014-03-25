import hxd.Key in K;
typedef Res = hxd.Res;

typedef AllKeys = { 
	up : Bool, 
	down : Bool, 
	left : Bool, 
	right : Bool, 
	a : Bool,
	z : Bool,
	e : Bool,
	shift : Bool, 
	cancel : Bool,
};

enum TypeEnt<T:Ent> {
	RIEN : TypeEnt<Ent>;
	TROUP : TypeEnt<IconeTroup>;
	ARROW : TypeEnt<Arrow>;
}

enum CodeTroup {
	CHASSEUR;
	ARCHER;
	TANK;
	SOLDAT;
	TROLL;
	MAGICIEN;
	NECROMANCIEN;
	ASSASSIN;
	ORACLE;
	HERO;
}

enum SkillCode {
	POISON; 
	PIEGE;
	
	TIR_BARRAGE;
	SPRINT;
	
	LEVER_BOUCLIER;
	COUP_BOUCLIER;
	
	FORMATION_SERREE;
	ATTAQUE_TOURNOYANTE;
	
	CHARGE_FRENETIC;
	BERSERK;
	
	TELEPORTATION;
	FIREBALL;
	
	CURSE;
	METAMORPHOSE;
	
	CLOACK;
	ASSASSINAT;
	
	MINDCONTROL;
	DODO;
	SCAN;
	
	POWER_AURA;
	RESURECT;	
}

enum TypeArrow {
	NORMAL;
	POISON;
	MAGIC;
	BARRAGE;
}

enum TypeDamage {
	PHYSIQUE;
	MAGIC;
	TIR;
}
