import alfy from 'alfy';
import { execSync } from 'node:child_process';
import path from 'node:path';
import os from 'node:os';

// --- Configuration ---
const searchPath = alfy.userConfig.get('search_path') || os.homedir();
const excludes = (alfy.userConfig.get('excludes') || 'node_modules;.git;.cache;Library').split(';');
const maxResults = parseInt(alfy.userConfig.get('max_results') || '100', 10);

// --- Helpers ---
function getIcon(filePath) {
	try {
		const stat = execSync(`test -d "${filePath}" && echo "dir" || echo "file"`, { encoding: 'utf8' }).trim();
		if (stat === 'dir') return '📁';
		const isExecutable = execSync(`test -x "${filePath}" && echo "yes" || echo "no"`, { encoding: 'utf8' }).trim();
		if (isExecutable === 'yes') return '⚡';
		return '📄';
	} catch {
		return '📄';
	}
}

function getEzaMetadata(filePath) {
	try {
		const result = execSync(
			`eza --icons=never --color=never --long --git --time-style=relative "${filePath}" 2>/dev/null`,
			{ encoding: 'utf8' }
		).trim();
		const parts = result.split(/\s+/);
		if (parts.length >= 7) {
			const perms = parts[1];
			const size = parts[2];
			const date = parts.slice(5, 7).join(' ');
			const gitStatus = parts[7] || '';
			return `${perms}  ${size}  ${date}  ${gitStatus}`.trim();
		}
		return '';
	} catch {
		return '';
	}
}

function runFd(searchPath, excludes) {
	const excludeArgs = excludes
		.filter(e => e)
		.map(e => `--exclude "${e}"`)
		.join(' ');

	try {
		const result = execSync(
			`fd --hidden ${excludeArgs} . "${searchPath}" 2>/dev/null`,
			{ encoding: 'utf8', maxBuffer: 10 * 1024 * 1024 }
		);
		return result.trim().split('\n').filter(Boolean);
	} catch {
		return [];
	}
}

// --- Main ---
const query = alfy.input.toLowerCase();

// Get candidates from fd
const candidates = runFd(searchPath, excludes).slice(0, maxResults * 2);

// Filter with alfy's fuzzy matching
const filtered = alfy.inputMatches(candidates, (item, input) => {
	const basename = path.basename(item).toLowerCase();
	const relPath = item.replace(os.homedir(), '~').toLowerCase();
	return basename.includes(input) || relPath.includes(input);
}).slice(0, maxResults);

// Build output items
const items = filtered.map(file => {
	const icon = getIcon(file);
	const basename = path.basename(file);
	const relPath = file.replace(os.homedir(), '~');
	const meta = getEzaMetadata(file);

	return {
		uid: file,
		title: `${icon} ${basename}`,
		subtitle: `${relPath}  ${meta}`,
		arg: file,
		type: 'file',
		icon: { type: 'fileicon', path: file },
		variables: { file_path: file, is_directory: String(file.endsWith('/')).toLowerCase() },
		mods: {
			cmd: {
				subtitle: 'Reveal in Finder',
				arg: file,
				variables: { action: 'reveal' }
			},
			alt: {
				subtitle: 'Open in Terminal',
				arg: file,
				variables: { action: 'terminal' }
			},
			ctrl: {
				subtitle: 'Copy path to clipboard',
				arg: file,
				variables: { action: 'copy' }
			}
		}
	};
});

alfy.output(items);
