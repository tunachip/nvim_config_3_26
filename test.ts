// tasks/test.ts

export function printSource (
	source: string,
): void {
	console.log(source);
}

const word1: string = 'wild';
const word2: Array<string> = [
	'w','i','l','d'
];

function main (
): void {
	for (let i = 0; i < word1.length; i++) {
		console.log(word1[i] === word2[i]);
	}
}

main()
