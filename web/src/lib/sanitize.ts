/** Devotional text is written by staff as HTML. Only plain formatting is kept; scripts, styles, frames and handlers are dropped. */
const ALLOWED = new Set(["P", "BR", "B", "STRONG", "I", "EM", "U", "H1", "H2", "H3", "H4", "UL", "OL", "LI", "BLOCKQUOTE", "A", "HR", "SPAN", "DIV"]);
const DROP = new Set(["SCRIPT", "STYLE", "IFRAME", "OBJECT", "EMBED", "LINK", "META", "FORM", "INPUT", "BUTTON", "SVG", "MATH", "NOSCRIPT", "TEMPLATE"]);

export function sanitizeHtml(html: string): string {
  const doc = new DOMParser().parseFromString(`<div>${html}</div>`, "text/html");
  const walk = (node: Element) => {
    for (const child of Array.from(node.children)) {
      if (DROP.has(child.tagName)) { child.remove(); continue; }
      walk(child);
      if (!ALLOWED.has(child.tagName)) { child.replaceWith(...Array.from(child.childNodes)); continue; }
      for (const attr of Array.from(child.attributes)) {
        const href = child.tagName === "A" && attr.name === "href" && /^(https?:|mailto:)/i.test(attr.value.trim());
        if (!href) child.removeAttribute(attr.name);
      }
      if (child.tagName === "A") { child.setAttribute("rel", "noopener noreferrer"); child.setAttribute("target", "_blank"); }
    }
  };
  walk(doc.body);
  return doc.body.firstElementChild?.innerHTML || "";
}

/** The embeddable player address for a YouTube link, or null when it is some other kind of video link. */
export function youtubeEmbed(url: string): string | null {
  try {
    const u = new URL(url);
    const host = u.hostname.replace(/^www\.|^m\./, "");
    let id = "";
    if (host === "youtu.be") id = u.pathname.slice(1);
    else if (host === "youtube.com" || host === "youtube-nocookie.com") {
      id = u.searchParams.get("v") || (/^\/(embed|shorts|live)\/([^/?]+)/.exec(u.pathname)?.[2] ?? "");
    }
    return /^[\w-]{6,20}$/.test(id) ? `https://www.youtube-nocookie.com/embed/${id}` : null;
  } catch {
    return null;
  }
}
