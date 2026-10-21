
using UnityEngine;

[RequireComponent(typeof(Renderer))]
public class FogPlayerExclusion : MonoBehaviour
{
    [Header("Player")]
    [SerializeField] private Transform player;

    private Renderer fogRenderer;
    private MaterialPropertyBlock properties;

    private static readonly int PlayerPositionID =
        Shader.PropertyToID("_PlayerPosition");

    private void Awake()
    {
        fogRenderer = GetComponent<Renderer>();
        properties = new MaterialPropertyBlock();
    }

    private void LateUpdate()
    {
        if (player == null || fogRenderer == null)
            return;

        fogRenderer.GetPropertyBlock(properties);

        properties.SetVector(
            PlayerPositionID,
            player.position
        );

        fogRenderer.SetPropertyBlock(properties);
    }
}
