
using UnityEngine;

public class MagicTreeActivation : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private Transform player;
    [SerializeField] private Renderer[] treeRenderers;

    [Header("Activation")]
    [SerializeField, Min(0.1f)] private float activationDistance = 4f;
    [SerializeField, Min(0.1f)] private float waveSpeed = 3f;
    [SerializeField, Min(0.1f)] private float treeHeight = 6f;
    [SerializeField, Min(0f)] private float glowDuration = 2f;

    private MaterialPropertyBlock block;
    private float waveHeight;
    private float glowTimer;
    private bool active;

    private static readonly int WaveHeightID =
        Shader.PropertyToID("_WaveHeight");

    private static readonly int ActivationID =
        Shader.PropertyToID("_Activation");

    private void Awake()
    {
        block = new MaterialPropertyBlock();

        if (treeRenderers == null || treeRenderers.Length == 0)
            treeRenderers = GetComponentsInChildren<Renderer>();
    }

    private void Update()
    {
        if (player == null)
            return;

        float distance = Vector3.Distance(
            player.position,
            transform.position
        );

        if (!active && distance <= activationDistance)
        {
            active = true;
            waveHeight = transform.position.y;
            glowTimer = glowDuration;
        }

        if (!active)
            return;

        waveHeight += waveSpeed * Time.deltaTime;
        glowTimer -= Time.deltaTime;

        float activation = Mathf.Clamp01(
            glowTimer / Mathf.Max(glowDuration, 0.01f)
        );

        foreach (Renderer treeRenderer in treeRenderers)
        {
            if (treeRenderer == null)
                continue;

            treeRenderer.GetPropertyBlock(block);

            block.SetFloat(WaveHeightID, waveHeight);
            block.SetFloat(ActivationID, activation);

            treeRenderer.SetPropertyBlock(block);
        }

        if (waveHeight > transform.position.y + treeHeight)
        {
            active = false;

            foreach (Renderer treeRenderer in treeRenderers)
            {
                if (treeRenderer == null)
                    continue;

                treeRenderer.GetPropertyBlock(block);
                block.SetFloat(ActivationID, 0f);
                block.SetFloat(WaveHeightID, -100f);
                treeRenderer.SetPropertyBlock(block);
            }
        }
    }
}
