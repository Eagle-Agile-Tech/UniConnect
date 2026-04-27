"""Turn dataset userFeatures / targetFeatures into strings for the encoder."""

from __future__ import annotations

from datetime import datetime, timezone


def _to_list(value: object) -> list[str]:
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        return [str(x) for x in value if x]
    return [str(value)]


def interaction_to_text(breakdown: dict | None) -> str:
    if not breakdown or not isinstance(breakdown, dict):
        return "No interaction history details were recorded."
    parts: list[str] = []
    for key, value in sorted(breakdown.items(), key=lambda x: str(x[0])):
        try:
            count = int(value)
        except Exception:
            continue
        if count <= 0:
            continue
        parts.append(f"{key} ({count} times)")
    if not parts:
        return "No interaction history details were recorded."
    return "Frequently interacts through: " + ", ".join(parts) + "."


def recency_to_text(latest_interaction_at: object) -> str:
    if not latest_interaction_at:
        return "Recency unknown."
    try:
        raw = str(latest_interaction_at).replace("Z", "+00:00")
        ts = datetime.fromisoformat(raw)
        if ts.tzinfo is None:
            ts = ts.replace(tzinfo=timezone.utc)
        now = datetime.now(timezone.utc)
        days_ago = max(0, int((now - ts).total_seconds() // 86400))
    except Exception:
        return "Recency unknown."

    if days_ago <= 1:
        return "Recently interacted with similar content."
    if days_ago <= 7:
        return f"Interacted with similar content {days_ago} days ago."
    return f"Last similar interaction was about {days_ago} days ago."


def score_to_soft_label(row: dict) -> float:
    label_raw = row.get("label", 0)
    try:
        label = float(label_raw)
    except Exception:
        label = 0.0
    if label <= 0:
        return 0.0

    # Use richer supervision when aggregate score exists.
    score_raw = row.get("totalScore")
    if score_raw is None:
        return min(max(label, 0.0), 1.0)
    try:
        total_score = float(score_raw)
    except Exception:
        return min(max(label, 0.0), 1.0)
    return min(max(total_score / 100.0, 0.0), 1.0)


def user_features_to_text(features: dict | None) -> str:
    if not features or not isinstance(features, dict):
        return (
            "User profile is sparse. Interests are unknown and listed skills are unknown."
        )
    interests = _to_list(features.get("interests"))
    skills = _to_list(features.get("skills"))
    preferred_categories = _to_list(features.get("preferredCategories"))
    history = features.get("history") if isinstance(features.get("history"), list) else []
    university = features.get("university") or "unknown university"
    department = features.get("department") or "undisclosed department"
    level = features.get("level") or "unknown level"
    i = ", ".join(interests) if interests else "general campus topics"
    s = ", ".join(skills) if skills else "no explicit skills"
    p = (
        ", ".join(preferred_categories)
        if preferred_categories
        else "broad campus and learning categories"
    )
    history_parts: list[str] = []
    for entry in history[:3]:
        if not isinstance(entry, dict):
            continue
        interaction_type = entry.get("interactionType") or "interaction"
        target_type = entry.get("targetType") or "content"
        history_parts.append(f"{interaction_type.lower()} on {target_type.lower()}")
    history_text = (
        " Recent history includes "
        + ", ".join(history_parts)
        + "."
        if history_parts
        else ""
    )
    return (
        f"A student interested in {i}. "
        f"Their skills include {s}. "
        f"They often prefer {p}. "
        f"They study at {university} in {department} and are at {level}. "
        "Likely values practical, community-driven learning experiences."
        f"{history_text}"
    )


def target_features_to_text(target_type: str, features: dict | None) -> str:
    if not features or not isinstance(features, dict):
        return f"type {target_type or 'UNKNOWN'}: no description."
    t = (target_type or features.get("type") or "").upper()
    if t == "POST":
        content = features.get("content") or ""
        tags = _to_list(features.get("tags"))
        cat = features.get("category") or ""
        tag_s = ", ".join(tags) if tags else "general"
        return (
            f"Social post in category {cat or 'general'}. "
            f"Tags: {tag_s}. "
            f"Post content: {content}. "
            "The post may support peer discussion, discovery, and practical learning."
        )
    if t == "EVENT":
        title = features.get("title") or ""
        uni = features.get("university") or ""
        desc = features.get("description") or ""
        return (
            f"Campus event at {uni or 'a university'}. "
            f"Title: {title}. "
            f"Description: {desc or 'Student activity and learning focused event.'} "
            "Likely relevant to networking and hands-on participation."
        )
    if t == "COURSE":
        title = features.get("title") or ""
        desc = features.get("description") or ""
        price = features.get("price")
        p = "not specified" if price is None else str(price)
        return (
            f"Structured course content. "
            f"Title: {title}. "
            f"Price: {p}. "
            f"Description: {desc}. "
            "The course emphasizes educational progression and skill development."
        )
    return f"item. {features}"


def row_to_pair(row: dict) -> tuple[str, str, float] | None:
    uf = row.get("userFeatures")
    tf = row.get("targetFeatures")
    tt = row.get("targetType") or ""
    label = score_to_soft_label(row)
    if uf is None or tf is None:
        return None
    interaction_text = interaction_to_text(row.get("interactionBreakdown"))
    recency_text = recency_to_text(row.get("latestInteractionAt"))
    u = " ".join([user_features_to_text(uf), interaction_text, recency_text])
    v = target_features_to_text(tt, tf)
    return u, v, label
