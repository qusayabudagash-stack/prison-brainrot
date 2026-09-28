-- Shared type definitions for saved player data and roll results.

export type PlayerData = {
	version: number,
	coins: number,
	totalEarned: number,
	-- [brainrotId] = { Normal = n, Golden = n, Diamond = n }
	brainrots: { [string]: { [string]: number } },
	discovered: { [string]: boolean },
	variantsFound: { [string]: { [string]: boolean } },
	upgrades: { [string]: number },
	unlockedAreas: { [string]: boolean },
	rebirths: number,
	pity: number,
	totalRolls: number,
	bestRarity: number,
	lastDailyRoll: number,
	boostUntil: number,
	freeBoostReadyAt: number,
	achievements: { [string]: boolean },
	cosmetics: { [string]: boolean },
	tutorialDone: boolean,
	luck: number,
	meta: { [string]: any },
}

export type RollResult = {
	brainrotId: string,
	variant: string,
	rarity: string,
	isNew: boolean,
	isNewVariant: boolean,
	pity: number,
	areaId: string,
	free: boolean,
	speed: number,
	source: string,
}

-- The snapshot the server sends to a client whenever its data changes.
export type State = {
	data: PlayerData,
	income: number,
	baseIncome: number,
	capacity: number,
	permanentLuck: number,
	serverTime: number,
}

return {}
