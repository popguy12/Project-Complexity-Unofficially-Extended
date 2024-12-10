// [gng] partially based on beautiful doom's smoke
// https://github.com/jekyllgrim/Beautiful-Doom/blob/96fcd0cec039eca762a8b206e522e8111a62ad95/Z_BDoom/bd_main.zc#L932
class PC_GunFireSmoke: Actor
{
    Default
	{
        Alpha 0.75;
        //Scale 0.2;
        Renderstyle "Add";
        Speed 1;
        BounceFactor 0;
        Radius 0;
        Height 0;
        Mass 0;
        +NOBLOCKMAP;
        +NOTELEPORT;
        +DONTSPLASH;
        +MISSILE;
        +FORCEXYBILLBOARD;
        //+CLIENTSIDEONLY;
        +NOINTERACTION;
        +NOGRAVITY;
        +THRUACTORS;
        +ROLLSPRITE;
        +ROLLCENTER;
        +NOCLIP;
    }

    double dissipateRotation;
    vector3 posOfs;
    int m_sprite;

    override void PostBeginPlay()
    {
        dissipateRotation = frandom(0.7, 1.4) * randompick(-1, 1);
        bXFLIP = randompick(0, 1);
        bYFLIP = randompick(0, 1);
        m_sprite = random(0, 17);
    }

    States 
    {
        Spawn:
            SM0K A 1 {
                invoker.frame = invoker.m_sprite;
                if(GetAge() < 18) 
                {
                    A_Fadeout(0.015, FTF_CLAMP|FTF_REMOVE);
                    scale *= 1.02;
                    vel *= 0.85;
                    roll += dissipateRotation;
                    dissipateRotation *= 0.96;
                    
                    if(CeilingPic == SkyFlatNum) {
                        vel.y += 0.02; // wind
                        vel.z += 0.01;
                        vel.x -= 0.01;
                    }
                }
                else
                {
                    A_Fadeout(0.01 , FTF_CLAMP|FTF_REMOVE);
                    scale *= 1.01;
                    vel *= 0.7;
                    roll += dissipateRotation;
                    dissipateRotation *= 0.95;
                    
                    if(CeilingPic == SkyFlatNum) {
                        vel.y += 0.03; // wind
                        vel.z += 0.015;
                        vel.x -= 0.015;
                    }

                    if (alpha < 0.1)
                        A_FadeOut(0.005, FTF_CLAMP|FTF_REMOVE);
                }
            }
            Loop;
    }
}

class PC_Smoke : Actor abstract
{
	override void BeginPlay()
	{
		Super.BeginPlay();
		GrowSpeed = frandom(GSMin, GSMax);
		FadeSpeed = frandom(FSMin, FSMax);
		StopSpeed = frandom(SSMin, SSMax);
		MoveDir = randompick(-1, 1);
		A_SetRoll(random(0, 360));
	}

	void ScaleSmoke(Vector2 scl)
	{
		Scale.X *= scl.X;
		Scale.Y *= scl.Y;
		GrowSpeed *= min(scl.X, scl.Y);
		FadeSpeed /= min(scl.X, scl.Y);
		StopSpeed *= min(scl.X, scl.Y) ** 0.2;
	}

	override void Tick()
	{
		if (--ReactionTime < 0 && !bNEVERCOLLIDE)
		{
			bNOINTERACTION = false; // [Ace] We don't want a blockmap, but we do want geometry collision, hence the lack of A_ChangeLinkFlags.
		}

		GrowSpeed *= GrowStopFactor;
		
		Vel *= StopSpeed;
		if (!bSTANDSTILL)
		{
			if (Pos.Z > FloorZ)
			{
				Vel.Z -= Gravity;
			}
			else if (Vel.Length() < 1)
			{
				A_ChangeVelocity(0, 0.15 * MoveDir, 0, CVF_RELATIVE | CVF_REPLACE);
			}
		}
		else if (Pos.Z > FloorZ)
		{
			Vel.Z -= Gravity;
		}

		Super.Tick();

		// [Ace] If you spawn a smoke and it walks into a different sector with a different height, it will automatically get moved to the floor.
		// We don't want that, it looks weird. In that case, enforce no geometry collision.
		if (!bNOINTERACTION && abs(Pos.Z - Prev.Z) > 16 && Vel.Z < 16)
		{
			bNEVERCOLLIDE = true;
			bNOINTERACTION = true;
			SetOrigin(Prev, false);
		}
	}

	protected int MoveDir;

	double GrowSpeed;
	protected meta double GSMin, GSMax;
	property GrowSpeed: GSMin, GSMax;

	protected meta double GrowStopFactor;
	property GrowStopFactor: GrowStopFactor;

	double FadeSpeed;
	protected meta double FSMin, FSMax;
	property FadeSpeed: FSMin, FSMax;

	double StopSpeed;
	protected meta double SSMin, SSMax;
	property StopSpeed: SSMin, SSMax;

	private int SmokeFlags;
	flagdef NeverCollide: SmokeFlags, 0;

	Default
	{
		PC_Smoke.GrowSpeed 0.00275, 0.003;
		PC_Smoke.FadeSpeed 0.00275, 0.003;
		PC_Smoke.StopSpeed 0.95, 0.95;
		PC_Smoke.GrowStopFactor 0.98;
		Radius 5;
		Height 10;
		Scale 0.02;
		Gravity 0.022;
		+NOINTERACTION
		+NOBLOCKMAP
		+NOGRAVITY
		+THRUACTORS
		+ROLLSPRITE
		+FORCEXYBILLBOARD
		+DONTSPLASH
		+NOTIMEFREEZE
		+NOTRIGGER
		MaxStepHeight 8;
		ReactionTime 6;
		Scale 0.05;
		Alpha 0.35;
	}

	States
	{
		Spawn:
			GNSM # 1
			{
				A_FadeOut(FadeSpeed);
				A_SetScale(Scale.X + GrowSpeed);
			}
			Loop;
	}
}

class PC_ExplosionSmoke : PC_Smoke
{
	Default
	{
		Scale 0.4;
		PC_Smoke.FadeSpeed 0.003, 0.007;
		PC_Smoke.GrowSpeed 0.006, 0.010;
		PC_Smoke.StopSpeed 0.80, 0.88;
	}

	States
	{
		Spawn:
			GNSM L 0;
			Goto Super::Spawn;
	}
}