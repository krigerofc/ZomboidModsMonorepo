# Pending real-game acceptance —2.2.1

These checks have NOT been run. The user requested no game launches by the agent.

- On ordinary42.19.2 single-player, corpse camouflage must be unavailable with an explanatory tooltip and no new blood/exposure.
- In an isolated debug-SP world, complete the corpse action; check zombie pursuit, attacks and sound behaviour, duration, washing, running and attacking. Verify cancelling an unfinished action grants nothing.
- With an isolated dedicated/hosted server and two ordinary clients using identical2.2.1, repeat the action. Check the wearer and another player's visibility, client-owned zombies, existing pursuit and new arrivals. Native invisibility is broader than zombie-only camouflage.
- Join while another player is disguised; check vanilla-flag-before-lease ordering. Briefly interrupt packet flow: camouflage must clear within five real seconds, then recover only with a newer authorized lease. A genuinely revoked serial must stay revoked.
- Check late join, online ID reuse, split-screen, mismatched versions, sandbox disabled, death, disconnect/reconnect, saving and reload. No saved camouflage may be restored. Verify no ordinary character remains invisible afterward.
- Test without FieldMedicine, with it disabled, and with its Exposure API active. Washing should remove corresponding regional exposure; expiry leaves residual blood risk when medicine is active.
- Start with admin/another mod invisibility already enabled: server must refuse camouflage and preserve that flag. Concurrent writers of the same flag are unsupported.

Do not publish as gameplay-validated until these checks pass. Use disposable test data, never existing saves.
