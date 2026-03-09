CREATE OR REPLACE FUNCTION sync_activity_status_from_session()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'active' AND NEW.ended_at IS NULL THEN
        UPDATE activities
        SET
            status = 'in_progress',
            updated_at = NOW()
        WHERE id = NEW.activity_id
          AND status <> 'cancelled';
    ELSIF NEW.status = 'ended' OR NEW.ended_at IS NOT NULL THEN
        UPDATE activities
        SET
            status = 'completed',
            updated_at = NOW()
        WHERE id = NEW.activity_id
          AND status <> 'cancelled';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS on_session_status_sync_activity ON sessions;
CREATE TRIGGER on_session_status_sync_activity
    AFTER INSERT OR UPDATE OF status, ended_at ON sessions
    FOR EACH ROW
    EXECUTE FUNCTION sync_activity_status_from_session();

UPDATE activities AS a
SET
    status = CASE
        WHEN EXISTS (
            SELECT 1
            FROM sessions AS s
            WHERE s.activity_id = a.id
              AND s.status = 'active'
              AND s.ended_at IS NULL
        ) THEN 'in_progress'
        WHEN EXISTS (
            SELECT 1
            FROM sessions AS s
            WHERE s.activity_id = a.id
              AND (s.status = 'ended' OR s.ended_at IS NOT NULL)
        ) THEN 'completed'
        ELSE a.status
    END,
    updated_at = NOW()
WHERE a.status <> 'cancelled'
  AND a.status IS DISTINCT FROM CASE
      WHEN EXISTS (
          SELECT 1
          FROM sessions AS s
          WHERE s.activity_id = a.id
            AND s.status = 'active'
            AND s.ended_at IS NULL
      ) THEN 'in_progress'
      WHEN EXISTS (
          SELECT 1
          FROM sessions AS s
          WHERE s.activity_id = a.id
            AND (s.status = 'ended' OR s.ended_at IS NOT NULL)
      ) THEN 'completed'
      ELSE a.status
  END;
